local framework = require 'bridge.framework'
local spellmeConfig = require 'config.server.spellme'

--- Build a lookup set for valid words
local validWords = {}
for _, word in ipairs(spellmeConfig.answers) do
    validWords[word] = true
end
for _, word in ipairs(spellmeConfig.allowedGuesses) do
    validWords[word] = true
end

MySQL.ready(function()
    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_spellme` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `username` VARCHAR(255) NOT NULL,
            `word` VARCHAR(10) NOT NULL,
            `date` DATE NOT NULL,
            `guesses` TEXT NOT NULL,
            `attempts` INT NOT NULL DEFAULT 0,
            `won` TINYINT(1) NOT NULL DEFAULT 0,
            `completed` TINYINT(1) NOT NULL DEFAULT 0,
            `completed_at` TIMESTAMP NULL,
            UNIQUE KEY `unique_player_date` (`identifier`, `date`)
        )
    ]], {})

    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_spellme_words` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `word` VARCHAR(10) NOT NULL,
            `date` DATE NOT NULL UNIQUE
        )
    ]], {})
end)

--- Get today's daily word from the database, inserting a new random word if needed
---@return { word: string, wordNumber: number }
local function getDailyWord()
    local today = os.date('%Y-%m-%d')
    local row = MySQL.single.await('SELECT id, word FROM `fd_laptop_spellme_words` WHERE date = ?', { today })

    if row then
        return { word = row.word, wordNumber = row.id }
    end

    local index = math.random(1, #spellmeConfig.answers)
    local word = spellmeConfig.answers[index]

    local id = MySQL.insert.await('INSERT INTO `fd_laptop_spellme_words` (word, date) VALUES (?, ?)', { word, today })

    if not id then
        row = MySQL.single.await('SELECT id, word FROM `fd_laptop_spellme_words` WHERE date = ?', { today })
        if row then
            return { word = row.word, wordNumber = row.id }
        end
    end

    return { word = word, wordNumber = id }
end

--- Generate feedback for a guess against the target word
---@param guess string
---@param target string
---@return table feedback array of {letter, status} where status is 'correct'|'present'|'absent'
local function generateFeedback(guess, target)
    local feedback = {}
    local targetLetters = {}

    -- First pass: mark correct letters
    for i = 1, 5 do
        local g = guess:sub(i, i)
        local t = target:sub(i, i)
        if g == t then
            feedback[i] = { letter = g, status = 'correct' }
        else
            targetLetters[t] = (targetLetters[t] or 0) + 1
        end
    end

    -- Second pass: mark present/absent
    for i = 1, 5 do
        if not feedback[i] then
            local g = guess:sub(i, i)
            if targetLetters[g] and targetLetters[g] > 0 then
                feedback[i] = { letter = g, status = 'present' }
                targetLetters[g] = targetLetters[g] - 1
            else
                feedback[i] = { letter = g, status = 'absent' }
            end
        end
    end

    return feedback
end

--- Get username for a player
---@param identifier string
---@return string
local function getUsername(identifier)
    local result = MySQL.scalar.await('SELECT username FROM `fd_laptop` WHERE identifier = ?', { identifier })
    return result or 'Unknown'
end

--- Get game state callback
---@param source number
---@return table
lib.callback.register('fd_laptop:server:spellmeGetState', function(source)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local today = os.date('%Y-%m-%d')
    local row = MySQL.single.await('SELECT * FROM `fd_laptop_spellme` WHERE identifier = ? AND date = ?', { identifier, today })

    local daily = getDailyWord()

    if not row then
        return {
            guesses = {},
            feedback = {},
            status = 'playing',
            attemptsUsed = 0,
            maxAttempts = spellmeConfig.maxAttempts,
            wordNumber = daily.wordNumber
        }
    end

    local guesses = json.decode(row.guesses) or {}

    -- Regenerate feedback for each guess
    local allFeedback = {}
    for _, guess in ipairs(guesses) do
        allFeedback[#allFeedback + 1] = generateFeedback(guess, daily.word)
    end

    local status = 'playing'
    if row.completed then
        status = row.won and 'won' or 'lost'
    end

    return {
        guesses = guesses,
        feedback = allFeedback,
        status = status,
        attemptsUsed = row.attempts,
        maxAttempts = spellmeConfig.maxAttempts,
        word = status == 'lost' and daily.word or nil,
        wordNumber = daily.wordNumber
    }
end)

--- Submit guess callback
---@param source number
---@param data table
---@return table
lib.callback.register('fd_laptop:server:spellmeGuess', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local guess = data and data.guess
    if not guess or type(guess) ~= 'string' then
        return { error = 'Invalid guess' }
    end

    guess = guess:upper()

    if #guess ~= 5 then
        return { error = 'Guess must be 5 letters' }
    end

    if not guess:match('^%a+$') then
        return { error = 'Guess must contain only letters' }
    end

    if not validWords[guess] then
        return { error = 'Not a valid word' }
    end

    local today = os.date('%Y-%m-%d')
    local daily = getDailyWord()
    local dailyWord = daily.word

    local row = MySQL.single.await('SELECT * FROM `fd_laptop_spellme` WHERE identifier = ? AND date = ?', { identifier, today })

    local guesses = {}
    local attempts = 0

    if row then
        if row.completed then
            return { error = 'Game already completed for today' }
        end
        guesses = json.decode(row.guesses) or {}
        attempts = row.attempts
    end

    if attempts >= spellmeConfig.maxAttempts then
        return { error = 'No attempts remaining' }
    end

    -- Add guess
    guesses[#guesses + 1] = guess
    attempts = attempts + 1

    local feedback = generateFeedback(guess, dailyWord)
    local won = guess == dailyWord
    local completed = won or attempts >= spellmeConfig.maxAttempts

    local username = getUsername(identifier)

    if row then
        MySQL.update([[
            UPDATE `fd_laptop_spellme`
            SET guesses = ?, attempts = ?, won = ?, completed = ?, completed_at = ?
            WHERE identifier = ? AND date = ?
        ]], {
            json.encode(guesses),
            attempts,
            won and 1 or 0,
            completed and 1 or 0,
            completed and os.date('%Y-%m-%d %H:%M:%S') or nil,
            identifier,
            today
        })
    else
        MySQL.insert([[
            INSERT INTO `fd_laptop_spellme` (identifier, username, word, date, guesses, attempts, won, completed, completed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            identifier,
            username,
            dailyWord,
            today,
            json.encode(guesses),
            attempts,
            won and 1 or 0,
            completed and 1 or 0,
            completed and os.date('%Y-%m-%d %H:%M:%S') or nil
        })
    end

    -- Regenerate all feedback
    local allFeedback = {}
    for _, g in ipairs(guesses) do
        allFeedback[#allFeedback + 1] = generateFeedback(g, dailyWord)
    end

    local status = 'playing'
    if completed then
        status = won and 'won' or 'lost'
    end

    return {
        guesses = guesses,
        feedback = allFeedback,
        status = status,
        attemptsUsed = attempts,
        maxAttempts = spellmeConfig.maxAttempts,
        word = status == 'lost' and dailyWord or nil,
        wordNumber = daily.wordNumber
    }
end)

--- Get leaderboard callback
---@param source number
---@param data table
---@return table
lib.callback.register('fd_laptop:server:spellmeLeaderboard', function(source, data)
    local period = data and data.period or 'daily'

    if period == 'daily' then
        local today = os.date('%Y-%m-%d')
        local rows = MySQL.query.await([[
            SELECT username, attempts, won
            FROM `fd_laptop_spellme`
            WHERE date = ? AND won = 1
            ORDER BY attempts ASC
            LIMIT 20
        ]], { today })

        return rows or {}

    elseif period == 'weekly' then
        local today = os.date('%Y-%m-%d')
        local rows = MySQL.query.await([[
            SELECT username,
                   SUM(won) AS wins,
                   ROUND(AVG(CASE WHEN won = 1 THEN attempts END), 1) AS avgAttempts
            FROM `fd_laptop_spellme`
            WHERE YEARWEEK(date, 3) = YEARWEEK(?, 3)
            GROUP BY identifier, username
            HAVING wins > 0
            ORDER BY wins DESC, avgAttempts ASC
            LIMIT 20
        ]], { today })

        return rows or {}

    else
        local rows = MySQL.query.await([[
            SELECT username,
                   SUM(won) AS wins,
                   ROUND(AVG(CASE WHEN won = 1 THEN attempts END), 1) AS avgAttempts
            FROM `fd_laptop_spellme`
            GROUP BY identifier, username
            HAVING wins > 0
            ORDER BY wins DESC, avgAttempts ASC
            LIMIT 20
        ]], {})

        return rows or {}
    end
end)
