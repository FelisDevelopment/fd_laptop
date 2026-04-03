<script lang="ts">
  import { localeStore } from '$lib/stores/localeStore.svelte'

  let { onsubmit, oncancel }: {
    onsubmit?: (password: string) => void
    oncancel?: () => void
  } = $props()

  let password = $state('')

  function connect() {
    if (!password) return
    onsubmit?.(password)
  }

  function cancel() {
    oncancel?.()
  }
</script>

<div class="flex flex-col gap-4">
  <div class="flex flex-col gap-1.5">
    <label for="password" class="text-xs font-medium text-[#8B8D9A]">
      {localeStore.t('wifi_password_field_helptext')}
    </label>
    <input
      id="password"
      type="password"
      bind:value={password}
      class="w-full rounded-lg border border-[#2D2F3A] bg-[#16171C] px-3 py-2 text-sm text-[#F0F0F5] outline-none transition-colors focus:border-[#7C8AED]"
      aria-describedby="password-help"
    />
  </div>
  <div class="flex items-center gap-2">
    <button
      type="button"
      class="flex-1 rounded-lg bg-[#5BBD6B] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[#4DAD5D] disabled:opacity-50"
      onclick={connect}
      disabled={!password}
    >
      {localeStore.t('wifi_connect_button')}
    </button>
    <button
      type="button"
      class="flex-1 rounded-lg border border-[#2D2F3A] px-4 py-2 text-sm font-medium text-[#F0F0F5] transition-colors hover:bg-[#252730]"
      onclick={cancel}
    >
      {localeStore.t('wifi_connect_cancel_button')}
    </button>
  </div>
</div>
