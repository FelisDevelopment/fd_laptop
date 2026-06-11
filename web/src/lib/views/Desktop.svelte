<script lang="ts">
  import { onMount } from 'svelte'
  import { appsStore, type DesktopApp } from '$lib/stores/appsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { iconUrl } from '$lib/utils/url.utils'
  import ContextMenu from '$lib/components/ContextMenu.svelte'

  const CELL_W = 96
  const CELL_H = 112
  const MARGIN = 2

  let { parent }: { parent: HTMLDivElement } = $props()

  let activeItem = $state<string | undefined>()
  let selectedApp = $state<string | undefined>()
  let contextMenuRef = $state<ContextMenu | undefined>()
  let desktopRef = $state<HTMLDivElement | null>(null)
  let gridRef = $state<HTMLDivElement | null>(null)
  let cols = $state(16)

  let contextMenuItems = $derived([
    {
      label: localeStore.t('remove_shortcut_label'),
      command: () => {
        appsStore.removeDesktopIcon(selectedApp!)
      }
    }
  ])

  function openContextMenu(event: MouseEvent, id: string) {
    event.stopPropagation()
    event.preventDefault()

    if (!contextMenuRef) return

    const bounds = parent.getBoundingClientRect()
    selectedApp = id

    contextMenuRef.show({
      x: event.clientX - bounds.left,
      y: event.clientY - bounds.top
    })
  }

  function appName(id: string): string | undefined {
    return appsStore.appsById.get(id)?.name
  }

  function appIcon(id: string): string | undefined {
    return appsStore.appsById.get(id)?.icon
  }

  let dragItem = $state<DesktopApp | null>(null)
  let dragEl = $state<HTMLElement | null>(null)
  let ghostCol = $state(-1)
  let ghostRow = $state(-1)
  let cachedGridRect: DOMRect | null = null
  let dragStartX = 0
  let dragStartY = 0
  let hasMoved = $state(false)

  function cellFromPointer(clientX: number, clientY: number): { col: number; row: number } | null {
    if (!cachedGridRect) return null
    const x = clientX - cachedGridRect.left
    const y = clientY - cachedGridRect.top
    if (x < 0 || y < 0) return null

    const col = Math.floor(x / (CELL_W + MARGIN))
    const row = Math.floor(y / (CELL_H + MARGIN))

    if (col >= cols || row >= appsStore.desktopRows) return null
    return { col, row }
  }

  function onPointerDown(e: PointerEvent, item: DesktopApp) {
    if (e.button !== 0) return

    dragItem = item
    dragEl = e.currentTarget as HTMLElement
    dragStartX = e.clientX
    dragStartY = e.clientY
    hasMoved = false
    cachedGridRect = gridRef?.getBoundingClientRect() ?? null
    dragEl.setPointerCapture(e.pointerId)
    e.preventDefault()
  }

  function onPointerMove(e: PointerEvent) {
    if (!dragItem || !dragEl) return

    const dx = e.clientX - dragStartX
    const dy = e.clientY - dragStartY

    if (!hasMoved && Math.abs(dx) < 5 && Math.abs(dy) < 5) return
    hasMoved = true

    dragEl.style.transform = `translate(${dx}px, ${dy}px)`
    dragEl.style.zIndex = '50'

    const cell = cellFromPointer(e.clientX, e.clientY)
    if (cell) {
      ghostCol = cell.col
      ghostRow = cell.row
    }
  }

  function onPointerUp(e: PointerEvent) {
    if (!dragItem || !dragEl) return

    dragEl.style.transform = ''
    dragEl.style.zIndex = ''

    if (hasMoved) {
      const cell = cellFromPointer(e.clientX, e.clientY)
      if (cell) {
        const { col, row } = cell

        const occupant = appsStore.desktopApps.find(
          (item) => item !== dragItem && item.x === col && item.y === row
        )

        if (occupant) {
          occupant.x = dragItem!.x
          occupant.y = dragItem!.y
        }

        dragItem!.x = col
        dragItem!.y = row

        appsStore.saveDesktopApps()
      }
    }

    clearDrag()
  }

  function clearDrag() {
    if (dragEl) {
      dragEl.style.transform = ''
      dragEl.style.zIndex = ''
    }
    dragItem = null
    dragEl = null
    ghostCol = -1
    ghostRow = -1
    cachedGridRect = null
    hasMoved = false
  }

  function computeCols() {
    if (!desktopRef) return
    cols = Math.floor(desktopRef.clientWidth / CELL_W) || 16
  }

  function computeRows() {
    if (!desktopRef || desktopRef.clientHeight === 0) return
    const rows = Math.floor(desktopRef.clientHeight / (CELL_H + MARGIN))
    if (rows > 0) {
      appsStore.desktopRows = rows
      appsStore.fixOutOfBoundsApps()
    }
  }

  onMount(() => {
    computeCols()
    computeRows()

    const observer = new ResizeObserver(() => {
      computeCols()
      computeRows()
    })
    if (desktopRef) observer.observe(desktopRef)

    return () => observer.disconnect()
  })

  let showGhost = $derived(
    dragItem !== null && hasMoved && ghostCol >= 0 && ghostRow >= 0
  )
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  class="desktop-icons z-10 h-full w-full overflow-hidden"
  bind:this={desktopRef}
  onclick={() => activeItem = undefined}
>
  <div
    bind:this={gridRef}
    class="desktop-grid relative"
    style="display: grid; grid-template-columns: repeat({cols}, {CELL_W}px); grid-auto-rows: {CELL_H}px; gap: {MARGIN}px; width: 100%; height: 100%;"
  >
    {#each appsStore.filteredDesktopApps as item (item.appId)}
      <!-- svelte-ignore a11y_no_static_element_interactions -->
      <div
        class="app z-10 flex h-28 w-24 select-none flex-col items-center justify-center rounded-sm border border-transparent hover:bg-white hover:bg-opacity-10 focus:bg-blue-500 focus:bg-opacity-10 {activeItem === item.appId ? 'bg-blue-500 bg-opacity-10 hover:bg-blue-500' : ''} {dragItem === item && hasMoved ? 'opacity-40' : ''}"
        style="grid-column: {item.x + 1}; grid-row: {item.y + 1}; touch-action: none; cursor: auto;"
        onpointerdown={(e) => onPointerDown(e, item)}
        onpointermove={onPointerMove}
        onpointerup={onPointerUp}
        onclick={(e) => { e.stopPropagation(); activeItem = item.appId }}
        ondblclick={(e) => { e.stopPropagation(); appsStore.open(item.appId) }}
        oncontextmenu={(e) => { e.stopPropagation(); openContextMenu(e, item.appId) }}
      >
        {#if appIcon(item.appId)}
          <img src={iconUrl(appIcon(item.appId)!)} width="43" height="43" alt="" draggable="false" />
        {/if}
        <span class="text-center text-xs text-[#fafafa] my-1 [text-shadow:0_0_4px_rgba(0,0,0,0.6)]">{appName(item.appId)}</span>
      </div>
    {/each}

    {#if showGhost}
      <div
        class="pointer-events-none rounded-sm border-2 border-dashed border-white/40 bg-white/10"
        style="grid-column: {ghostCol + 1}; grid-row: {ghostRow + 1};"
      ></div>
    {/if}
  </div>

  <ContextMenu
    bind:this={contextMenuRef}
    items={contextMenuItems}
    onhide={() => selectedApp = undefined}
  />
</div>
