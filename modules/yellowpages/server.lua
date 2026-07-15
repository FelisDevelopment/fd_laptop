local framework = require 'bridge.framework'
local config = require 'config.server.yellowpages'

local function textLen(s)
    return utf8.len(s) or #s
end

MySQL.ready(function()
    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_yellowpages` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `username` VARCHAR(255) NOT NULL,
            `name` VARCHAR(255) NOT NULL,
            `description` TEXT NULL,
            `phone` VARCHAR(32) NULL,
            `image_url` TEXT NULL,
            `status` VARCHAR(16) NOT NULL DEFAULT 'approved',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_identifier` (`identifier`),
            INDEX `idx_status` (`status`)
        )
    ]], {})

    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_yellowpages_reviews` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `listing_id` INT NOT NULL,
            `identifier` VARCHAR(255) NOT NULL,
            `username` VARCHAR(255) NOT NULL,
            `rating` TINYINT NOT NULL,
            `comment` TEXT NULL,
            `reported` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_review` (`listing_id`, `identifier`),
            INDEX `idx_listing` (`listing_id`)
        )
    ]], {})

    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_yellowpages_bans` (
            `identifier` VARCHAR(255) NOT NULL PRIMARY KEY,
            `banned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})
end)

local function getUsername(identifier)
    local result = MySQL.scalar.await('SELECT username FROM `fd_laptop` WHERE identifier = ?', { identifier })
    return result or 'Unknown'
end

local function isBanned(identifier)
    return MySQL.scalar.await('SELECT identifier FROM `fd_laptop_yellowpages_bans` WHERE identifier = ?', { identifier }) ~= nil
end

local function mapListing(row, identifier)
    return {
        id = row.id,
        name = row.name,
        description = row.description,
        phone = row.phone,
        imageUrl = row.image_url,
        status = row.status,
        isOwner = row.identifier == identifier,
        avgRating = row.avg_rating and tonumber(row.avg_rating) or 0,
        reviewCount = row.review_count or 0,
        createdAt = row.created_at
    }
end

local function getListingById(id, identifier)
    local row = MySQL.single.await([[
        SELECT l.*, ROUND(AVG(r.`rating`), 1) AS avg_rating, COUNT(r.`id`) AS review_count
        FROM `fd_laptop_yellowpages` l
        LEFT JOIN `fd_laptop_yellowpages_reviews` r ON r.`listing_id` = l.`id`
        WHERE l.`id` = ?
        GROUP BY l.`id`
    ]], { id })
    if not row then return nil end
    return mapListing(row, identifier)
end

local function mapReview(row, identifier)
    return {
        id = row.id,
        rating = row.rating,
        comment = row.comment,
        username = row.username,
        isOwn = row.identifier == identifier,
        reported = row.reported == 1,
        createdAt = row.created_at
    }
end

lib.callback.register('fd_laptop:server:yellowpagesGetListings', function(source)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local rows = MySQL.query.await([[
        SELECT l.*, ROUND(AVG(r.`rating`), 1) AS avg_rating, COUNT(r.`id`) AS review_count
        FROM `fd_laptop_yellowpages` l
        LEFT JOIN `fd_laptop_yellowpages_reviews` r ON r.`listing_id` = l.`id`
        WHERE l.`status` = 'approved' OR l.`identifier` = ?
        GROUP BY l.`id`
        ORDER BY l.`created_at` DESC
    ]], { identifier })

    local listings = {}
    for _, row in ipairs(rows or {}) do
        listings[#listings + 1] = mapListing(row, identifier)
    end
    return listings
end)

lib.callback.register('fd_laptop:server:yellowpagesCreateListing', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local name = data and data.name
    if not name or name == '' then return { error = 'Name is required' } end
    if textLen(name) > config.maxNameLength then return { error = 'Name is too long' } end
    if data.description and textLen(data.description) > config.maxDescriptionLength then
        return { error = 'Description is too long' }
    end
    if data.phone and #data.phone > 32 then return { error = 'Phone is too long' } end
    if data.imageUrl and (#data.imageUrl > config.maxImageUrlLength or not data.imageUrl:match('^https?://')) then
        return { error = 'Invalid image URL' }
    end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM `fd_laptop_yellowpages` WHERE identifier = ?', { identifier })
    if count and count >= config.maxListingsPerPlayer then
        return { error = 'You have reached your listing limit' }
    end

    local status = config.requireApproval and 'pending' or 'approved'
    local username = getUsername(identifier)

    local id = MySQL.insert.await([[
        INSERT INTO `fd_laptop_yellowpages` (`identifier`, `username`, `name`, `description`, `phone`, `image_url`, `status`)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { identifier, username, name, data.description or nil, data.phone or nil, data.imageUrl or nil, status })

    return getListingById(id, identifier)
end)

lib.callback.register('fd_laptop:server:yellowpagesUpdateListing', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local id = data and data.id
    local name = data and data.name
    if not id then return { error = 'Listing id is required' } end
    if not name or name == '' then return { error = 'Name is required' } end
    if textLen(name) > config.maxNameLength then return { error = 'Name is too long' } end
    if data.description and textLen(data.description) > config.maxDescriptionLength then
        return { error = 'Description is too long' }
    end
    if data.phone and #data.phone > 32 then return { error = 'Phone is too long' } end
    if data.imageUrl and (#data.imageUrl > config.maxImageUrlLength or not data.imageUrl:match('^https?://')) then
        return { error = 'Invalid image URL' }
    end

    local affected = MySQL.update.await([[
        UPDATE `fd_laptop_yellowpages`
        SET `name` = ?, `description` = ?, `phone` = ?, `image_url` = ?
        WHERE `id` = ? AND `identifier` = ?
    ]], { name, data.description or nil, data.phone or nil, data.imageUrl or nil, id, identifier })

    if affected == 0 then return { error = 'Listing not found' } end
    return getListingById(id, identifier)
end)

lib.callback.register('fd_laptop:server:yellowpagesDeleteListing', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local id = data and data.id
    if not id then return { error = 'Listing id is required' } end

    local affected = MySQL.update.await(
        'DELETE FROM `fd_laptop_yellowpages` WHERE `id` = ? AND `identifier` = ?', { id, identifier })
    if affected == 0 then return { error = 'Listing not found' } end

    MySQL.update('DELETE FROM `fd_laptop_yellowpages_reviews` WHERE `listing_id` = ?', { id })
    return { success = true }
end)

lib.callback.register('fd_laptop:server:yellowpagesGetReviews', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local listingId = data and data.listingId
    if not listingId then return { error = 'Listing id is required' } end

    local rows = MySQL.query.await([[
        SELECT * FROM `fd_laptop_yellowpages_reviews` WHERE `listing_id` = ? ORDER BY `created_at` DESC
    ]], { listingId })

    local reviews = {}
    for _, row in ipairs(rows or {}) do
        reviews[#reviews + 1] = mapReview(row, identifier)
    end
    return reviews
end)

lib.callback.register('fd_laptop:server:yellowpagesCreateReview', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local listingId = data and data.listingId
    local rating = data and data.rating
    if not listingId then return { error = 'Listing id is required' } end
    if type(rating) ~= 'number' or rating < 1 or rating > 5 or rating % 1 ~= 0 then
        return { error = 'Rating must be between 1 and 5' }
    end
    if data.comment and textLen(data.comment) > config.maxCommentLength then
        return { error = 'Comment is too long' }
    end

    if isBanned(identifier) then return { error = 'You are banned from reviewing' } end

    local ownerIdentifier = MySQL.scalar.await('SELECT identifier FROM `fd_laptop_yellowpages` WHERE id = ?', { listingId })
    if not ownerIdentifier then return { error = 'Listing not found' } end
    if ownerIdentifier == identifier then return { error = 'You cannot review your own listing' } end

    local existing = MySQL.scalar.await(
        'SELECT id FROM `fd_laptop_yellowpages_reviews` WHERE `listing_id` = ? AND `identifier` = ?', { listingId, identifier })
    if existing then return { error = 'You have already reviewed this listing' } end

    local username = getUsername(identifier)
    local id = MySQL.insert.await([[
        INSERT INTO `fd_laptop_yellowpages_reviews` (`listing_id`, `identifier`, `username`, `rating`, `comment`)
        VALUES (?, ?, ?, ?, ?)
    ]], { listingId, identifier, username, rating, data.comment or nil })

    local row = MySQL.single.await('SELECT * FROM `fd_laptop_yellowpages_reviews` WHERE id = ?', { id })
    return mapReview(row, identifier)
end)

lib.callback.register('fd_laptop:server:yellowpagesUpdateReview', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local id = data and data.id
    local rating = data and data.rating
    if not id then return { error = 'Review id is required' } end
    if type(rating) ~= 'number' or rating < 1 or rating > 5 or rating % 1 ~= 0 then
        return { error = 'Rating must be between 1 and 5' }
    end
    if data.comment and textLen(data.comment) > config.maxCommentLength then
        return { error = 'Comment is too long' }
    end

    local affected = MySQL.update.await([[
        UPDATE `fd_laptop_yellowpages_reviews` SET `rating` = ?, `comment` = ?
        WHERE `id` = ? AND `identifier` = ?
    ]], { rating, data.comment or nil, id, identifier })
    if affected == 0 then return { error = 'Review not found' } end

    local row = MySQL.single.await('SELECT * FROM `fd_laptop_yellowpages_reviews` WHERE id = ?', { id })
    return mapReview(row, identifier)
end)

lib.callback.register('fd_laptop:server:yellowpagesDeleteReview', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local id = data and data.id
    if not id then return { error = 'Review id is required' } end

    local affected = MySQL.update.await(
        'DELETE FROM `fd_laptop_yellowpages_reviews` WHERE `id` = ? AND `identifier` = ?', { id, identifier })
    if affected == 0 then return { error = 'Review not found' } end
    return { success = true }
end)

lib.callback.register('fd_laptop:server:yellowpagesReportReview', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then return { error = 'Unable to identify player' } end

    local id = data and data.id
    if not id then return { error = 'Review id is required' } end

    local listingId = MySQL.scalar.await('SELECT listing_id FROM `fd_laptop_yellowpages_reviews` WHERE id = ?', { id })
    if not listingId then return { error = 'Review not found' } end

    local ownerIdentifier = MySQL.scalar.await('SELECT identifier FROM `fd_laptop_yellowpages` WHERE id = ?', { listingId })
    if ownerIdentifier ~= identifier then return { error = 'Only the listing owner can report reviews' } end

    MySQL.update('UPDATE `fd_laptop_yellowpages_reviews` SET `reported` = 1 WHERE `id` = ?', { id })
    return { success = true }
end)

exports('deleteListing', function(id)
    if not id then return false end
    MySQL.update('DELETE FROM `fd_laptop_yellowpages_reviews` WHERE `listing_id` = ?', { id })
    local affected = MySQL.update.await('DELETE FROM `fd_laptop_yellowpages` WHERE `id` = ?', { id })
    return (affected or 0) > 0
end)

exports('approveListing', function(id)
    if not id then return false end
    local affected = MySQL.update.await("UPDATE `fd_laptop_yellowpages` SET `status` = 'approved' WHERE `id` = ?", { id })
    return (affected or 0) > 0
end)

exports('getPendingListings', function()
    return MySQL.query.await("SELECT * FROM `fd_laptop_yellowpages` WHERE `status` = 'pending' ORDER BY `created_at` ASC") or {}
end)

exports('deleteReview', function(id)
    if not id then return false end
    local affected = MySQL.update.await('DELETE FROM `fd_laptop_yellowpages_reviews` WHERE `id` = ?', { id })
    return (affected or 0) > 0
end)

exports('getReportedReviews', function()
    return MySQL.query.await([[
        SELECT r.*, l.`name` AS listing_name
        FROM `fd_laptop_yellowpages_reviews` r
        JOIN `fd_laptop_yellowpages` l ON l.`id` = r.`listing_id`
        WHERE r.`reported` = 1
        ORDER BY r.`created_at` DESC
    ]]) or {}
end)

exports('banReviewer', function(identifier)
    if not identifier then return false end
    MySQL.update('INSERT IGNORE INTO `fd_laptop_yellowpages_bans` (`identifier`) VALUES (?)', { identifier })
    return true
end)

exports('unbanReviewer', function(identifier)
    if not identifier then return false end
    MySQL.update('DELETE FROM `fd_laptop_yellowpages_bans` WHERE `identifier` = ?', { identifier })
    return true
end)
