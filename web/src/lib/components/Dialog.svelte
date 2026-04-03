<script lang="ts">
  import type { Snippet } from 'svelte'

  let { header = '', visible = false, onclose, children }: {
    header?: string
    visible?: boolean
    onclose?: () => void
    children?: Snippet
  } = $props()
</script>

{#if visible}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50"
    onclick={(e) => { if (e.target === e.currentTarget && onclose) onclose() }}
  >
    <div class="w-80 rounded-xl bg-[#1E2028] shadow-lg">
      <div class="flex items-center justify-between border-b border-[#2D2F3A] px-4 py-3">
        <h3 class="text-sm font-semibold text-[#F0F0F5]">{header}</h3>
        <button
          type="button"
          aria-label="Close"
          class="flex h-6 w-6 items-center justify-center rounded-lg text-[#8B8D9A] transition-colors hover:bg-[#252730]"
          onclick={onclose}
        >
          <i class="fa-solid fa-xmark text-xs"></i>
        </button>
      </div>
      <div class="p-4">
        {@render children?.()}
      </div>
    </div>
  </div>
{/if}
