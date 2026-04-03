<script lang="ts">
  import type { ToastItem } from '$lib/stores/notificationsStore.svelte'
  import NotificationItem from './NotificationItem.svelte'

  let { toast, onclose }: {
    toast: ToastItem
    onclose?: () => void
  } = $props()
</script>

<NotificationItem
  summary={toast.summary}
  detail={toast.detail}
  variant="toast"
  {onclose}
/>
