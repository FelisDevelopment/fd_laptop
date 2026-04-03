<script lang="ts">
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fly } from 'svelte/transition'
  import NotificationItem from '$lib/components/NotificationItem.svelte'

  let { isOpen = false, onclose }: {
    isOpen?: boolean
    onclose?: () => void
  } = $props()

  function openSettings() {
    onclose?.()
    appsStore.open('settings', { tab: 'notifications' })
  }
</script>

{#if isOpen}
  <div
    id="notifications-area"
    class="fixed bottom-20 right-4 top-4 z-[999] flex w-96 transform flex-col rounded-2xl bg-[#1E2028] shadow-xl"
    transition:fly={{ x: 400, duration: 300 }}
  >
    <div class="flex flex-1 flex-col overflow-hidden">
      <div class="flex items-center justify-between px-5 py-4">
        <span class="text-base font-semibold text-gray-100">{localeStore.t('notifications_overlay_title')}</span>
        <button
          type="button"
          aria-label="Close"
          class="flex h-7 w-7 items-center justify-center rounded-lg text-gray-400 transition-colors hover:bg-gray-700/80 hover:text-gray-100"
          onclick={onclose}
        >
          <i class="fa-solid fa-xmark text-xs"></i>
        </button>
      </div>
      <div
        class="flex-1 space-y-2 overflow-y-auto px-4 pb-2 scrollbar-thin scrollbar-track-rounded-[100px] scrollbar-thumb-rounded-[100px] scrollbar-corner-rounded-[100px] scrollbar-track-gray-500/80 scrollbar-thumb-gray-400/80"
      >
        {#each notificationsStore.notifications as notification, index}
          <NotificationItem
            summary={notification.summary}
            detail={notification.detail}
            timestamp={notification.time}
            variant="overlay"
            onclose={() => notificationsStore.close(index)}
          />
        {/each}
      </div>
      <div class="flex justify-between border-t border-gray-700/50 px-2 py-2">
        <button
          type="button"
          class="rounded-lg px-3 py-1.5 text-[13px] font-medium text-[#7C8AED] transition-colors hover:bg-[#7C8AED]/10"
          onclick={openSettings}
        >
          {localeStore.t('notifications_overlay_settings_button')}
        </button>
        <button
          type="button"
          class="rounded-lg px-3 py-1.5 text-[13px] font-medium text-[#7C8AED] transition-colors hover:bg-[#7C8AED]/10"
          onclick={() => notificationsStore.clear()}
        >
          {localeStore.t('notifications_overlay_clear_button')}
        </button>
      </div>
    </div>
  </div>
{/if}
