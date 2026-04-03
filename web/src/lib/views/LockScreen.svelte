<script lang="ts">
  import { onMount } from 'svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'

  let inputEl = $state<HTMLInputElement | null>(null)
  let password = $state('')
  let error = $state('')
  let loading = $state(false)
  let showPassword = $state(false)

  async function handleUnlock() {
    if (loading || !password.trim()) return

    error = ''
    loading = true

    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'validateLaptopPassword',
      { method: 'POST', body: JSON.stringify({ password: password.trim() }) },
      { success: true }
    )

    loading = false

    if (result?.success) {
      password = ''
      laptopStore.unlock()
      return
    }

    error = localeStore.t('lock_screen_wrong_password')
    password = ''
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter') {
      handleUnlock()
    } else if (e.key === 'Escape') {
      laptopStore.close(true)
    }
  }

  onMount(() => {
    inputEl?.focus()
  })
</script>

<div class="absolute inset-0 z-50 flex flex-col items-center justify-center bg-[#16171C]/95 backdrop-blur-sm">
  <div class="flex flex-col items-center gap-6 w-72">
    <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#1E2028] border border-[#2D2F3A]">
      <i class="fa-solid fa-lock text-2xl text-[#8B8D9A]"></i>
    </div>

    <div class="flex flex-col items-center gap-1">
      <span class="text-lg font-semibold text-[#F0F0F5]">{localeStore.t('lock_screen_title')}</span>
      <span class="text-xs text-[#8B8D9A]">{localeStore.t('lock_screen_description')}</span>
    </div>

    <div class="flex flex-col gap-2 w-full">
      <div class="relative">
        <input
          bind:this={inputEl}
          type={showPassword ? 'text' : 'password'}
          class="w-full rounded-xl bg-[#1E2028] border px-4 py-3 pr-10 text-sm text-[#F0F0F5] outline-none transition-colors duration-150 placeholder:text-[#50525E] focus:border-[#7C8AED] {error ? 'border-[#E55B5B]' : 'border-[#2D2F3A]'}"
          placeholder={localeStore.t('lock_screen_placeholder')}
          bind:value={password}
          onkeydown={handleKeydown}
          disabled={loading}
        />
        <button
          type="button"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-[#50525E] transition-colors duration-150 hover:text-[#8B8D9A]"
          onclick={() => showPassword = !showPassword}
          aria-label="Toggle password"
        >
          <i class="fa-solid {showPassword ? 'fa-eye-slash' : 'fa-eye'} text-xs"></i>
        </button>
      </div>

      {#if error}
        <span class="text-xs text-[#E55B5B] text-center">{error}</span>
      {/if}
    </div>

    <button
      type="button"
      class="w-full rounded-xl bg-[#7C8AED] py-3 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#6B79DC] disabled:opacity-50"
      onclick={handleUnlock}
      disabled={loading || !password.trim()}
    >
      {#if loading}
        <i class="fa-solid fa-spinner fa-spin"></i>
      {:else}
        {localeStore.t('lock_screen_unlock')}
      {/if}
    </button>
  </div>
</div>
