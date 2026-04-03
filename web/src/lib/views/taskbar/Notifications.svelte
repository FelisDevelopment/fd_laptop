<script lang="ts">
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import NotificationsOverlay from '../overlays/NotificationsOverlay.svelte'

  let isOpen = $state(false)
</script>

<NotificationsOverlay {isOpen} onclose={() => isOpen = false} />
<button
  id="notifications-toggle"
  onclick={() => isOpen = !isOpen}
  type="button"
  aria-label="Notifications"
  class="relative flex h-8 w-8 items-center justify-center rounded-lg transition-colors hover:bg-white/10 focus:outline-none active:scale-95 active:bg-white/15"
>
  {#if notificationsStore.hasNotifications}
    <span class="absolute right-1 top-1 block h-1.5 w-1.5 rounded-full bg-red-500"></span>
  {/if}
  <i
    class="fa-solid"
    class:fa-bell={!settingsStore.doNotDisturb}
    class:fa-bell-slash={settingsStore.doNotDisturb}
  ></i>
</button>
