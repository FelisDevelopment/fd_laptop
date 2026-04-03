<script lang="ts">
  import { notificationsStore, type ToastItem } from '$lib/stores/notificationsStore.svelte'
  import ToastMessage from './ToastMessage.svelte'

  let { position = 'bottom-right', show = true }: {
    position?: 'bottom-right' | 'top-center'
    show?: boolean
  } = $props()

  let positionClasses = $derived(
    position === 'top-center'
      ? 'top-4 left-1/2 -translate-x-1/2 w-4/5'
      : 'bottom-20 right-4 w-80'
  )
</script>

{#if show && notificationsStore.toasts.length > 0}
  <div class="absolute z-[9999] flex flex-col gap-2 {positionClasses}">
    {#each notificationsStore.toasts as toast (toast.id)}
      <ToastMessage {toast} onclose={() => notificationsStore.removeToast(toast.id)} />
    {/each}
  </div>
{/if}
