<script lang="ts">
  import { formatDistanceToNow } from 'date-fns'
  import { localeStore } from '$lib/stores/localeStore.svelte'

  let { summary, detail, timestamp, onclose, variant = 'overlay' }: {
    summary: string
    detail: string
    timestamp?: Date
    onclose?: () => void
    variant?: 'toast' | 'overlay'
  } = $props()

  let containerClass = $derived(
    variant === 'toast'
      ? 'block space-y-1 rounded-xl bg-[#1E2028] p-3 text-sm shadow-sm hover:bg-[#252730] active:bg-[#1E2028]'
      : 'block space-y-1 rounded-xl bg-[#252730] p-3 text-sm transition-colors hover:bg-[#2D2F3A] active:bg-[#252730]'
  )
</script>

<div class={containerClass}>
  <div class="flex items-center justify-between">
    <h3 class="font-medium">{summary}</h3>
    <button
      type="button"
      aria-label="Dismiss"
      class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-gray-400 transition-colors hover:bg-gray-700 hover:text-gray-200"
      onclick={onclose}
    >
      <i class="fa-solid fa-xmark text-xs"></i>
    </button>
  </div>
  <p class="leading-5 text-gray-400">
    {detail}
  </p>
  {#if timestamp}
    <p class="text-gray-500">{formatDistanceToNow(timestamp, { addSuffix: true, locale: localeStore.dateFnsLocale })}</p>
  {/if}
</div>
