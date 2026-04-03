<script lang="ts">
  import { onMount } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { developmentStore } from '$lib/stores/developmentStore.svelte'
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { fetchApi } from '$lib/utils/api'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  type LetterStatus = 'correct' | 'present' | 'absent'
  interface LetterFeedback { letter: string; status: LetterStatus }
  interface GameState {
    guesses: string[]
    feedback: LetterFeedback[][]
    status: 'playing' | 'won' | 'lost'
    attemptsUsed: number
    maxAttempts: number
    word?: string
    error?: string
    wordNumber?: number
  }
  interface LeaderboardEntry {
    username: string
    attempts?: number
    wins?: number
    avgAttempts?: number
    won?: number
  }

  let modal = $state<'none' | 'help' | 'stats' | 'leaderboard'>('none')
  let leaderboardPeriod = $state<'daily' | 'weekly' | 'alltime'>('daily')
  let leaderboard = $state<LeaderboardEntry[]>([])
  let leaderboardLoading = $state(false)

  let guesses = $state<string[]>([])
  let feedback = $state<LetterFeedback[][]>([])
  let gameStatus = $state<'playing' | 'won' | 'lost'>('playing')
  let attemptsUsed = $state(0)
  let maxAttempts = $state(6)
  let revealedWord = $state<string | undefined>()
  let currentInput = $state('')
  let loading = $state(true)
  let submitting = $state(false)
  let errorMessage = $state<string | undefined>()
  let shakeRow = $state(-1)
  let revealRow = $state(-1)
  let wordNumber = $state<number | undefined>()

  const MOCK_WORDS = ['APPLE','BRAIN','CHAIR','DANCE','EAGLE','FLAME','GRAPE','HOUSE','IVORY','JOKER','KNIFE','LEMON','MANGO','NOBLE','OCEAN','PIANO','QUEEN','RIVER','STONE','TIGER']
  const MOCK_VALID_SET = new Set(MOCK_WORDS)
  const MOCK_WORD = MOCK_WORDS[Math.floor(Math.random() * MOCK_WORDS.length)]

  function mockFeedback(guess: string, target: string): LetterFeedback[] {
    const result: LetterFeedback[] = Array(5)
    const remaining: Record<string, number> = {}
    for (let i = 0; i < 5; i++) {
      if (guess[i] === target[i]) {
        result[i] = { letter: guess[i], status: 'correct' }
      } else {
        remaining[target[i]] = (remaining[target[i]] || 0) + 1
      }
    }
    for (let i = 0; i < 5; i++) {
      if (result[i]) continue
      if (remaining[guess[i]] && remaining[guess[i]] > 0) {
        result[i] = { letter: guess[i], status: 'present' }
        remaining[guess[i]]--
      } else {
        result[i] = { letter: guess[i], status: 'absent' }
      }
    }
    return result
  }

  const KEYBOARD_ROWS = [
    ['Q','W','E','R','T','Y','U','I','O','P'],
    ['A','S','D','F','G','H','J','K','L'],
    ['ENTER','Z','X','C','V','B','N','M','BACK']
  ]

  let keyStatuses = $derived.by(() => {
    const statuses: Record<string, LetterStatus> = {}
    for (const row of feedback) {
      for (const cell of row) {
        const existing = statuses[cell.letter]
        if (cell.status === 'correct') {
          statuses[cell.letter] = 'correct'
        } else if (cell.status === 'present' && existing !== 'correct') {
          statuses[cell.letter] = 'present'
        } else if (!existing) {
          statuses[cell.letter] = 'absent'
        }
      }
    }
    return statuses
  })

  async function loadGameState() {
    loading = true
    const mockState: GameState = {
      guesses: [],
      feedback: [],
      status: 'playing',
      attemptsUsed: 0,
      maxAttempts: 6,
      wordNumber: 1
    }
    const result = await fetchApi<GameState>('spellmeGetState', { method: 'POST', body: JSON.stringify({}) }, mockState)
    if (result) {
      guesses = result.guesses || []
      feedback = result.feedback || []
      gameStatus = result.status || 'playing'
      attemptsUsed = result.attemptsUsed || 0
      maxAttempts = result.maxAttempts || 6
      revealedWord = result.word
      wordNumber = result.wordNumber
    }
    loading = false
  }

  async function submitGuess() {
    if (submitting || gameStatus !== 'playing' || currentInput.length !== 5) return
    submitting = true
    errorMessage = undefined

    const guess = currentInput.toUpperCase()
    let mockResult: GameState
    if (!MOCK_VALID_SET.has(guess)) {
      mockResult = { guesses, feedback, status: gameStatus, attemptsUsed, maxAttempts, error: 'Not a valid word', wordNumber }
    } else {
      const newFeedback = mockFeedback(guess, MOCK_WORD)
      const newAttempts = attemptsUsed + 1
      const won = guess === MOCK_WORD
      const lost = !won && newAttempts >= maxAttempts
      mockResult = {
        guesses: [...guesses, guess],
        feedback: [...feedback, newFeedback],
        status: won ? 'won' : lost ? 'lost' : 'playing',
        attemptsUsed: newAttempts,
        maxAttempts,
        word: lost ? MOCK_WORD : undefined,
        wordNumber
      }
    }

    const result = await fetchApi<GameState>(
      'spellmeGuess',
      { method: 'POST', body: JSON.stringify({ guess: currentInput }) },
      mockResult
    )

    if (result) {
      if (result.error) {
        errorMessage = result.error
        shakeRow = attemptsUsed
        setTimeout(() => { shakeRow = -1 }, 600)
        setTimeout(() => { errorMessage = undefined }, 2500)
      } else {
        guesses = result.guesses || []
        feedback = result.feedback || []
        gameStatus = result.status || 'playing'
        attemptsUsed = result.attemptsUsed || 0
        maxAttempts = result.maxAttempts || 6
        revealedWord = result.word
        wordNumber = result.wordNumber
        currentInput = ''
        revealRow = attemptsUsed - 1
        setTimeout(() => { revealRow = -1 }, 1500)
      }
    }
    submitting = false
  }

  async function loadLeaderboard(period: 'daily' | 'weekly' | 'alltime') {
    leaderboardPeriod = period
    leaderboardLoading = true
    const mockData: LeaderboardEntry[] = [
      { username: 'Player1', attempts: 3, wins: 5, avgAttempts: 3.5, won: 1 },
      { username: 'Player2', attempts: 4, wins: 3, avgAttempts: 4.0, won: 1 },
    ]
    const result = await fetchApi<LeaderboardEntry[]>(
      'spellmeLeaderboard',
      { method: 'POST', body: JSON.stringify({ period }) },
      mockData
    )
    leaderboard = result || []
    leaderboardLoading = false
  }

  function onKeyPress(key: string) {
    if (gameStatus !== 'playing' || submitting) return
    if (key === 'ENTER') {
      submitGuess()
    } else if (key === 'BACK') {
      currentInput = currentInput.slice(0, -1)
    } else if (currentInput.length < 5) {
      currentInput = currentInput + key
    }
  }

  function handleKeydown(e: KeyboardEvent) {
    if (modal !== 'none') return
    if (gameStatus !== 'playing' || submitting) return
    if (e.key === 'Enter') { e.preventDefault(); submitGuess() }
    else if (e.key === 'Backspace') { e.preventDefault(); currentInput = currentInput.slice(0, -1) }
    else if (/^[a-zA-Z]$/.test(e.key) && currentInput.length < 5) { e.preventDefault(); currentInput = currentInput + e.key.toUpperCase() }
  }

  function openLeaderboard() {
    modal = 'leaderboard'
    loadLeaderboard(leaderboardPeriod)
  }

  function isWindowActive(): boolean {
    const win = appsStore.windows['spellme']
    return !!win && win.state.isActive && !win.state.isMinimized && !win.isHidden
  }

  function guardedKeydown(e: KeyboardEvent) {
    if (!isWindowActive()) return
    handleKeydown(e)
  }

  onMount(() => {
    changeWindowTitle(localeStore.t('spellme_title'))
    appReady()
    loadGameState()
    if (developmentStore.isDevEnv) {
      console.log(`%c[SpellMe] Today's word: ${MOCK_WORD}`, 'color: #68A149; font-weight: bold;')
    }
    document.addEventListener('keydown', guardedKeydown)
    return () => document.removeEventListener('keydown', guardedKeydown)
  })
</script>

<div class="flex-1 flex flex-col items-center bg-[#16171C] select-none overflow-hidden font-['Gilroy',Inter,sans-serif] relative">
  <div class="w-[344px] h-14 mt-6 bg-[#1E2028] border border-[#2D2F3A] rounded-xl flex items-center justify-center px-4 shrink-0 relative">
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button type="button" class="absolute left-4 w-7 h-7 flex items-center justify-center text-[#50525E] bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5]" onclick={() => { modal = 'help' }}>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/></svg>
    </button>

    <span class="text-[#F0F0F5] font-bold text-lg tracking-[0.02em]">{localeStore.t('spellme_title')}{wordNumber ? ` #${wordNumber}` : ''}</span>

    <div class="absolute right-4 flex items-center gap-3">
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center text-[#50525E] bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5]" onclick={() => { modal = 'stats' }}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 16V8"/><path d="M11 16V5"/><path d="M15 16v-5"/><path d="M19 16v-2"/></svg>
      </button>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center text-[#50525E] bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5]" onclick={openLeaderboard}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5C7.4 4 9 7 9 7"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5C16.6 4 15 7 15 7"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>
      </button>
    </div>
  </div>

  <div class="h-8 flex items-center justify-center shrink-0 mt-2">
    {#if gameStatus === 'won'}
      <div class="bg-[#F0F0F5] text-[#16171C] text-[13px] font-bold py-[6px] px-[18px] rounded-lg wdl-fade-in">{localeStore.t('spellme_won')}</div>
    {:else if gameStatus === 'lost'}
      <div class="bg-[#F0F0F5] text-[#16171C] text-[13px] font-bold py-[6px] px-[18px] rounded-lg wdl-fade-in">{localeStore.t('spellme_lost')}: <span class="tracking-[0.15em]">{revealedWord}</span></div>
    {:else if errorMessage}
      <div class="bg-[#F0F0F5] text-[#16171C] text-[13px] font-bold py-[6px] px-[18px] rounded-lg wdl-fade-in">{errorMessage}</div>
    {/if}
  </div>

  {#if loading}
    <div class="flex-1 flex items-center justify-center"><div class="w-[22px] h-[22px] border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
  {:else}
    <div class="flex flex-col gap-[6px] mt-[10px] shrink-0">
      {#each Array(maxAttempts) as _, rowIndex}
        {@const isCurrentRow = rowIndex === attemptsUsed && gameStatus === 'playing'}
        {@const rowGuess = guesses[rowIndex]}
        {@const rowFeedback = feedback[rowIndex]}
        {@const isRevealing = revealRow === rowIndex}
        <div class="flex gap-[6px] {shakeRow === rowIndex ? 'wdl-shake' : ''}">
          {#each Array(5) as _, colIndex}
            {@const letter = isCurrentRow ? (currentInput[colIndex] || '') : (rowGuess ? rowGuess[colIndex] : '')}
            {@const status = rowFeedback ? rowFeedback[colIndex]?.status : undefined}
            {@const hasLetter = letter !== ''}
            {@const isSubmitted = !!rowFeedback}
            <div
              class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg transition-colors duration-150
                {isRevealing ? 'wdl-reveal' : ''}
                {isCurrentRow && hasLetter ? 'wdl-pop' : ''}
                {isSubmitted && status === 'correct' ? 'bg-[#5BBD6B] border-2 border-[#5BBD6B]'
                  : isSubmitted && status === 'present' ? 'bg-[#E4A832] border-2 border-[#E4A832]'
                  : isSubmitted && status === 'absent' ? 'bg-[#252730] border-2 border-[#252730]'
                  : !isSubmitted && hasLetter ? 'bg-[#1E2028] border-2 border-[#3A3D4A]'
                  : 'bg-transparent border-2 border-[#2D2F3A]'}"
              style="{isRevealing ? `animation-delay: ${colIndex * 150}ms` : ''}"
            >{letter}</div>
          {/each}
        </div>
      {/each}
    </div>

    <div class="flex flex-col items-center gap-[5px] mt-auto pb-5 pt-6 shrink-0">
      {#each KEYBOARD_ROWS as row}
        <div class="flex gap-1">
          {#each row as key}
            {@const status = key !== 'ENTER' && key !== 'BACK' ? keyStatuses[key] : undefined}
            <button
              type="button"
              class="h-[42px] flex items-center justify-center font-bold uppercase text-[#F0F0F5] border-[1.5px] rounded-lg cursor-pointer transition-colors duration-150 disabled:opacity-30 disabled:cursor-default
                {key === 'ENTER' || key === 'BACK' ? 'w-auto min-w-[56px] px-3 text-xs tracking-[0.06em]' : 'w-10 text-base'}
                {status === 'correct' ? 'bg-[#5BBD6B] border-[#5BBD6B] enabled:hover:bg-[#4DAD5D] enabled:hover:border-[#4DAD5D]'
                  : status === 'present' ? 'bg-[#E4A832] border-[#E4A832] enabled:hover:bg-[#D49A28] enabled:hover:border-[#D49A28]'
                  : status === 'absent' ? 'bg-[#252730] border-[#252730] enabled:hover:bg-[#2D2F38] enabled:hover:border-[#2D2F38]'
                  : 'bg-[rgba(30,32,40,0.6)] border-[#2D2F3A] enabled:hover:bg-[rgba(45,47,58,0.6)] enabled:hover:border-[#3A3D4A]'}"
              onclick={() => onKeyPress(key)}
              disabled={gameStatus !== 'playing' || submitting}
            >
              {#if key === 'BACK'}
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z"/><path d="m12 9 6 6"/><path d="m18 9-6 6"/></svg>
              {:else}
                {key}
              {/if}
            </button>
          {/each}
        </div>
      {/each}
    </div>
  {/if}

  {#if modal === 'help'}
    <div class="absolute inset-0 z-50 flex items-center justify-center bg-[rgba(22,23,28,0.92)]">
      <div class="w-full h-full bg-[#16171C] flex flex-col items-center py-12 px-8 relative overflow-y-auto">
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="absolute top-6 right-6 w-7 h-7 flex items-center justify-center text-[#50525E] bg-none border-none cursor-pointer transition-colors duration-150 z-10 hover:text-[#F0F0F5]" onclick={() => { modal = 'none' }}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>

        <div class="w-10 h-10 rounded-xl border-2 border-[#E4A832] flex items-center justify-center text-[#E4A832] mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/></svg>
        </div>

        <h2 class="text-[#F0F0F5] font-bold text-[26px] mb-6">{localeStore.t('spellme_help_title')}</h2>

        <div class="text-center text-[#8B8D9A] text-sm leading-[22px] max-w-[420px] mb-9">
          <p class="mb-1">{localeStore.t('spellme_help_desc1')}</p>
          <p class="mb-1">{localeStore.t('spellme_help_desc2')}</p>
          <p class="mb-1">{localeStore.t('spellme_help_desc3')}</p>
        </div>

        <h3 class="text-[#F0F0F5] font-bold text-lg mb-5">{localeStore.t('spellme_help_examples')}</h3>

        <div class="flex flex-col items-center mb-4">
          <div class="flex gap-[6px]">
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#5BBD6B] border-2 border-[#5BBD6B]">L</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">O</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">P</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">A</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">S</div>
          </div>
          <p class="text-[#8B8D9A] text-[13px] mt-[10px]">{localeStore.t('spellme_help_correct')}</p>
        </div>

        <div class="flex flex-col items-center mb-4">
          <div class="flex gap-[6px]">
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">P</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#E4A832] border-2 border-[#E4A832]">O</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">V</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">A</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">S</div>
          </div>
          <p class="text-[#8B8D9A] text-[13px] mt-[10px]">{localeStore.t('spellme_help_present')}</p>
        </div>

        <div class="flex flex-col items-center mb-4">
          <div class="flex gap-[6px]">
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">P</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">O</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">V</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">A</div>
            <div class="w-16 h-16 flex items-center justify-center text-[22px] font-bold leading-[27px] uppercase text-[#F0F0F5] rounded-lg bg-[#252730] border-2 border-[#252730]">S</div>
          </div>
          <p class="text-[#8B8D9A] text-[13px] mt-[10px]">{localeStore.t('spellme_help_absent')}</p>
        </div>

        <p class="text-[#F0F0F5] font-medium text-[15px] mt-auto pt-7">{localeStore.t('spellme_help_footer')}</p>
      </div>
    </div>
  {/if}

  {#if modal === 'stats'}
    <div class="absolute inset-0 z-50 flex items-center justify-center bg-[rgba(22,23,28,0.92)]">
      <div class="relative bg-[#1E2028] border border-[#2D2F3A] rounded-2xl w-[460px] max-w-[calc(100%-40px)] p-7 shadow-lg">
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="absolute top-5 right-5 w-7 h-7 flex items-center justify-center text-[#8B8D9A] bg-none border-none cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5]" onclick={() => { modal = 'none' }}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>

        <h2 class="text-[#F0F0F5] font-bold text-[22px] text-center mb-5">{localeStore.t('spellme_stats_title')}</h2>

        <div class="flex justify-center gap-2 mb-6">
          <div class="flex flex-col items-center justify-center text-center bg-[#252730] border border-[#2D2F3A] rounded-xl w-24 h-[78px] py-3 px-2">
            <span class="text-[#F0F0F5] font-bold text-base leading-none mb-2">{attemptsUsed}</span>
            <span class="text-[#8B8D9A] font-medium text-[10px] leading-[1.3] whitespace-pre-wrap text-center">{localeStore.t('spellme_stats_played')}</span>
          </div>
          <div class="flex flex-col items-center justify-center text-center bg-[#252730] border border-[#2D2F3A] rounded-xl w-24 h-[78px] py-3 px-2">
            <span class="text-[#F0F0F5] font-bold text-base leading-none mb-2">{guesses.length > 0 ? Math.round((feedback.filter((_, i) => guesses[i] && feedback[i]?.every((f, j) => f.status === 'correct')).length / guesses.length) * 100) : 0}%</span>
            <span class="text-[#8B8D9A] font-medium text-[10px] leading-[1.3] whitespace-pre-wrap text-center">{localeStore.t('spellme_stats_winrate')}</span>
          </div>
          <div class="flex flex-col items-center justify-center text-center bg-[#252730] border border-[#2D2F3A] rounded-xl w-24 h-[78px] py-3 px-2">
            <span class="text-[#F0F0F5] font-bold text-base leading-none mb-2">0</span>
            <span class="text-[#8B8D9A] font-medium text-[10px] leading-[1.3] whitespace-pre-wrap text-center">{localeStore.t('spellme_stats_streak')}</span>
          </div>
          <div class="flex flex-col items-center justify-center text-center bg-[#252730] border border-[#2D2F3A] rounded-xl w-24 h-[78px] py-3 px-2">
            <span class="text-[#F0F0F5] font-bold text-base leading-none mb-2">0</span>
            <span class="text-[#8B8D9A] font-medium text-[10px] leading-[1.3] whitespace-pre-wrap text-center">{localeStore.t('spellme_stats_best_streak')}</span>
          </div>
        </div>

        <div class="text-center">
          <h3 class="text-[#F0F0F5] font-bold text-sm mb-1">{localeStore.t('spellme_stats_distribution')}</h3>
          <p class="text-[#8B8D9A] font-medium text-xs">{localeStore.t('spellme_stats_no_data')}</p>
        </div>
      </div>
    </div>
  {/if}

  {#if modal === 'leaderboard'}
    <div class="absolute inset-0 z-50 flex items-center justify-center bg-[rgba(22,23,28,0.92)]">
      <div class="w-full h-full bg-[#16171C] flex flex-col items-center py-12 px-8 relative overflow-y-auto">
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="absolute top-6 right-6 w-7 h-7 flex items-center justify-center text-[#50525E] bg-none border-none cursor-pointer transition-colors duration-150 z-10 hover:text-[#F0F0F5]" onclick={() => { modal = 'none' }}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>

        <h2 class="text-[#F0F0F5] font-bold text-[26px] mb-7">{localeStore.t('spellme_leaderboard_tab')}</h2>

        <div class="flex gap-[2px] bg-[#1E2028] border border-[#2D2F3A] rounded-xl p-1 mb-6">
          {#each [['daily', localeStore.t('spellme_lb_daily')], ['weekly', localeStore.t('spellme_lb_weekly')], ['alltime', localeStore.t('spellme_lb_alltime')]] as [period, label]}
            <button
              type="button"
              class="py-[6px] px-[14px] text-xs font-semibold border-none rounded-lg cursor-pointer transition-colors duration-150 tracking-[0.02em] {leaderboardPeriod === period ? 'bg-[#2D2F3A] text-[#F0F0F5]' : 'bg-none text-[#8B8D9A] hover:text-[#C0C2CC]'}"
              onclick={() => loadLeaderboard(period as 'daily' | 'weekly' | 'alltime')}
            >{label}</button>
          {/each}
        </div>

        {#if leaderboardLoading}
          <div class="flex-1 flex items-center justify-center"><div class="w-[22px] h-[22px] border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
        {:else if leaderboard.length === 0}
          <div class="flex-1 flex flex-col items-center justify-center gap-[10px] text-[#50525E] text-[13px]">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#333436" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5C7.4 4 9 7 9 7"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5C16.6 4 15 7 15 7"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>
            <span>{localeStore.t('spellme_lb_empty')}</span>
          </div>
        {:else}
          <div class="w-full max-w-[700px] px-6">
            <div class="w-full overflow-y-auto border border-[#2D2F3A] rounded-xl overflow-x-hidden lscrollbar">
              <div class="flex py-3 px-4 bg-[#1E2028] text-[13px] font-medium text-[#8B8D9A] sticky top-0">
                <span class="w-10 shrink-0 font-semibold">#</span>
                <span class="flex-1 truncate font-medium">{localeStore.t('spellme_lb_player')}</span>
                {#if leaderboardPeriod === 'daily'}
                  <span class="w-16 text-right shrink-0 font-semibold tabular-nums">{localeStore.t('spellme_lb_attempts')}</span>
                {:else}
                  <span class="w-16 text-right shrink-0 font-semibold tabular-nums">{localeStore.t('spellme_lb_wins')}</span>
                  <span class="w-16 text-right shrink-0 font-semibold tabular-nums">{localeStore.t('spellme_lb_avg')}</span>
                {/if}
              </div>
              {#each leaderboard as entry, i}
                <div class="flex py-[14px] px-4 border-t border-[#2D2F3A] text-sm font-medium text-[#F0F0F5]">
                  <span class="w-10 shrink-0 font-semibold {i === 0 ? 'text-[#FFD76B]' : i === 1 ? 'text-[#F0F0F5]' : i === 2 ? 'text-[#D0BF8D]' : 'text-[#8B8D9A]'}">{i + 1}</span>
                  <span class="flex-1 truncate font-medium">{entry.username}</span>
                  {#if leaderboardPeriod === 'daily'}
                    <span class="w-16 text-right shrink-0 font-semibold tabular-nums">{entry.attempts}/{maxAttempts}</span>
                  {:else}
                    <span class="w-16 text-right shrink-0 font-semibold tabular-nums">{entry.wins}</span>
                    <span class="w-16 text-right shrink-0 font-semibold tabular-nums">{entry.avgAttempts}</span>
                  {/if}
                </div>
              {/each}
            </div>
          </div>
        {/if}
      </div>
    </div>
  {/if}
</div>

<style>
  @keyframes wdl-pop {
    0% { transform: scale(1); }
    50% { transform: scale(1.1); }
    100% { transform: scale(1); }
  }
  .wdl-pop { animation: wdl-pop 0.1s ease-out; }

  @keyframes wdl-reveal {
    0% { transform: rotateX(0deg); }
    50% { transform: rotateX(90deg); }
    100% { transform: rotateX(0deg); }
  }
  .wdl-reveal { animation: wdl-reveal 0.5s ease forwards; }

  @keyframes wdl-shake {
    0%, 100% { transform: translateX(0); }
    10%, 50%, 90% { transform: translateX(-4px); }
    30%, 70% { transform: translateX(4px); }
  }
  .wdl-shake { animation: wdl-shake 0.4s ease-in-out; }

  @keyframes wdl-fade-in {
    from { opacity: 0; transform: translateY(-6px); }
    to { opacity: 1; transform: translateY(0); }
  }
  .wdl-fade-in { animation: wdl-fade-in 0.2s ease-out; }
</style>
