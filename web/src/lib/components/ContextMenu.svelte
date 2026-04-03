<script lang="ts">
  import { clickOutside } from '$lib/utils/clickOutside'

  interface MenuItem {
    label: string
    command: () => void
  }

  let { items = [], onhide }: {
    items?: MenuItem[]
    onhide?: () => void
  } = $props()

  let visible = $state(false)
  let x = $state(0)
  let y = $state(0)

  export function show(event: { x: number; y: number }) {
    x = event.x
    y = event.y
    visible = true
  }

  export function hide() {
    visible = false
    onhide?.()
  }
</script>

{#if visible}
  <div
    class="fixed z-[9999] min-w-40 rounded-md bg-gray-800 py-1 shadow-lg"
    style="left: {x}px; top: {y}px;"
    use:clickOutside={{ callback: hide }}
  >
    {#each items as item}
      <button
        type="button"
        class="flex w-full px-3 py-2 text-left text-sm text-gray-100 hover:bg-gray-700"
        onclick={() => { item.command(); hide() }}
      >
        {item.label}
      </button>
    {/each}
  </div>
{/if}
