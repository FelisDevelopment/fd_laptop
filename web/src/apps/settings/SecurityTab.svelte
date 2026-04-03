<script lang="ts">
  import { onMount } from 'svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  let newPassword = $state('')
  let confirmPassword = $state('')
  let error = $state('')
  let loading = $state(false)
  let showNew = $state(false)
  let showConfirm = $state(false)

  async function savePassword() {
    error = ''

    const trimmed = newPassword.trim()

    if (!trimmed && laptopStore.hasPassword) {
      const result = await fetchApi<{ success?: boolean; error?: string }>(
        'saveLaptopPassword',
        { method: 'POST', body: JSON.stringify({ password: '' }) },
        { success: true }
      )

      if (result?.success) {
        laptopStore.hasPassword = false
        notificationsStore.show({
          summary: localeStore.t('settings_security_removed_title'),
          detail: localeStore.t('settings_security_removed_description')
        })
        resetForm()
      }
      return
    }

    if (trimmed.length < 4) {
      error = localeStore.t('settings_security_min_length')
      return
    }

    if (trimmed !== confirmPassword.trim()) {
      error = localeStore.t('settings_security_mismatch')
      return
    }

    loading = true

    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'saveLaptopPassword',
      { method: 'POST', body: JSON.stringify({ password: trimmed }) },
      { success: true }
    )

    loading = false

    if (result?.success) {
      laptopStore.hasPassword = true
      notificationsStore.show({
        summary: localeStore.t('settings_security_saved_title'),
        detail: localeStore.t('settings_security_saved_description')
      })
      resetForm()
      return
    }

    error = result?.error || localeStore.t('settings_security_error')
  }

  function resetForm() {
    newPassword = ''
    confirmPassword = ''
    error = ''
    showNew = false
    showConfirm = false
  }

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_security_title'))
  })
</script>

<div class="flex flex-1 flex-col gap-4 overflow-auto">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_security_tab_label')}
  </h2>

  <div class="rounded-xl bg-[#1E2028] p-4">
    <div class="flex items-center gap-3 mb-4">
      <div class="flex h-7 w-7 items-center justify-center rounded-lg bg-[#7C8AED]">
        <i class="fa-solid fa-lock text-xs text-white"></i>
      </div>
      <div class="flex flex-col">
        <span class="text-sm font-medium text-[#F0F0F5]">
          {localeStore.t('settings_security_password_label')}
        </span>
        <span class="text-[11px] text-[#8B8D9A]">
          {laptopStore.hasPassword ? localeStore.t('settings_security_has_password') : localeStore.t('settings_security_no_password')}
        </span>
      </div>
    </div>

    <div class="flex flex-col gap-3">
      <div class="flex flex-col gap-1">
        <label for="new-password" class="text-xs font-medium text-[#8B8D9A]">
          {laptopStore.hasPassword ? localeStore.t('settings_security_new_password') : localeStore.t('settings_security_set_password')}
        </label>
        <div class="relative">
          <input
            id="new-password"
            type={showNew ? 'text' : 'password'}
            class="w-full rounded-lg border bg-[#16171C] px-3 py-2 pr-10 text-sm text-[#F0F0F5] outline-none transition-colors duration-150 focus:border-[#7C8AED] {error ? 'border-[#E55B5B]' : 'border-[#2D2F3A]'}"
            placeholder={localeStore.t('settings_security_password_placeholder')}
            bind:value={newPassword}
          />
          <button
            type="button"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-[#50525E] transition-colors duration-150 hover:text-[#8B8D9A]"
            onclick={() => showNew = !showNew}
            aria-label="Toggle password"
          >
            <i class="fa-solid {showNew ? 'fa-eye-slash' : 'fa-eye'} text-xs"></i>
          </button>
        </div>
      </div>

      <div class="flex flex-col gap-1">
        <label for="confirm-password" class="text-xs font-medium text-[#8B8D9A]">
          {localeStore.t('settings_security_confirm_password')}
        </label>
        <div class="relative">
          <input
            id="confirm-password"
            type={showConfirm ? 'text' : 'password'}
            class="w-full rounded-lg border bg-[#16171C] px-3 py-2 pr-10 text-sm text-[#F0F0F5] outline-none transition-colors duration-150 focus:border-[#7C8AED] border-[#2D2F3A]"
            placeholder={localeStore.t('settings_security_confirm_placeholder')}
            bind:value={confirmPassword}
          />
          <button
            type="button"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-[#50525E] transition-colors duration-150 hover:text-[#8B8D9A]"
            onclick={() => showConfirm = !showConfirm}
            aria-label="Toggle password"
          >
            <i class="fa-solid {showConfirm ? 'fa-eye-slash' : 'fa-eye'} text-xs"></i>
          </button>
        </div>
      </div>

      {#if error}
        <span class="text-xs text-[#E55B5B]">{error}</span>
      {/if}
    </div>

    <div class="flex gap-2 mt-4">
      <button
        type="button"
        class="flex-1 rounded-lg bg-[#5BBD6B] px-4 py-2 text-sm font-medium text-white transition-colors duration-150 hover:bg-[#4DAD5D] disabled:opacity-50"
        onclick={savePassword}
        disabled={loading || (!newPassword.trim() && !laptopStore.hasPassword)}
      >
        {#if loading}
          <i class="fa-solid fa-spinner fa-spin"></i>
        {:else}
          {localeStore.t('settings_security_save')}
        {/if}
      </button>

      {#if laptopStore.hasPassword}
        <button
          type="button"
          class="rounded-lg border border-[#2D2F3A] px-4 py-2 text-sm font-medium text-[#E55B5B] transition-colors duration-150 hover:border-[#E55B5B]"
          onclick={() => { newPassword = ''; confirmPassword = ''; savePassword() }}
          disabled={loading}
        >
          {localeStore.t('settings_security_remove')}
        </button>
      {/if}
    </div>
  </div>
</div>
