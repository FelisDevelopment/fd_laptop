<script lang="ts">
  import type { Window } from '$lib/types/window.types'
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { onMount } from 'svelte'
  import { debounce } from '$lib/utils/debounce'
  import ProgressSpinner from '$lib/components/ProgressSpinner.svelte'
  import InternalAppComponent from './windows/InternalAppComponent.svelte'
  import IframeAppComponent from './windows/IframeAppComponent.svelte'

  let { appWindow, parent }: {
    appWindow: Window
    parent: HTMLDivElement
  } = $props()

  let app = $derived(appWindow.app)
  let windowActions = $derived(appWindow.app.windowActions)
  let metadata = $derived(appWindow.metadata)
  let wState = $derived(appWindow.state)

  let windowEl = $state<HTMLDivElement | null>(null)

  let _windowWidth = $state<number | undefined>(undefined)
  let _windowHeight = $state<number | undefined>(undefined)
  let _x = $state<number | undefined>(undefined)
  let _y = $state<number | undefined>(undefined)
  let _title = $state<string | undefined>(undefined)

  let windowWidth = $derived(_windowWidth ?? appWindow.dimensions.width)
  let windowHeight = $derived(_windowHeight ?? appWindow.dimensions.height)
  let x = $derived(_x ?? appWindow.position[0]!)
  let y = $derived(_y ?? appWindow.position[1]!)
  let title = $derived(_title ?? appWindow.app.name)
  let isLoading = $state(true)

  let isDragging = $state(false)
  let dragStartX = 0
  let dragStartY = 0
  let dragOriginX = 0
  let dragOriginY = 0
  
  let translateX = $state(0)
  let translateY = $state(0)

  function onPointerDown(e: PointerEvent) {
    if (!windowActions.isDraggable) return
    if ((e.target as HTMLElement).closest('button')) return

    isDragging = true
    dragStartX = e.clientX
    dragStartY = e.clientY
    dragOriginX = x
    dragOriginY = y
    ;(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId)
    e.preventDefault()
  }

  function onPointerMove(e: PointerEvent) {
    if (!isDragging) return

    const dx = e.clientX - dragStartX
    const dy = e.clientY - dragStartY

    translateX = dx
    translateY = dy

    if (wState.isMaximized) {
      wState.isMaximized = false
    }
  }

  function onPointerUp() {
    if (isDragging) {
      _x = dragOriginX + translateX
      _y = dragOriginY + translateY
      translateX = 0
      translateY = 0
    }
    isDragging = false
  }

  let windowStyles = $derived.by(() => {
    const zIndex = wState.isActive ? 40 : 20

    if (wState.isMaximized) {
      return `inset: 0px; width: 100%; height: 100%; max-height: 100%; max-width: 100%; z-index: ${zIndex};`
    }

    let s = `top: ${y}px; left: ${x}px; width: ${windowWidth}px; min-width: ${appWindow.dimensions.minWidth}px; max-width: ${appWindow.dimensions.maxWidth}px; height: ${windowHeight}px; min-height: ${appWindow.dimensions.minHeight}px; max-height: ${appWindow.dimensions.maxHeight}px; z-index: ${zIndex};`

    if (translateX !== 0 || translateY !== 0) {
      s += ` transform: translate(${translateX}px, ${translateY}px);`
    }

    if (windowActions.isResizable) {
      s += ' resize: both;'
    }

    return s
  })

  function changeWindowTitle(newTitle: string) {
    _title = newTitle
  }

  function appReady() {
    isLoading = false
  }

  function minimize() {
    appsStore.toggleActiveState(app.id, false)
    appsStore.toggleMinimizeState(app.id, true)
  }

  function maximize() {
    wState.isMaximized = !wState.isMaximized
  }

  function close() {
    appsStore.close(app.id)
  }

  onMount(() => {
    if (!windowEl) return

    const handleResize = debounce((entries: ResizeObserverEntry[]) => {
      const entry = entries[0]
      const { width: newWidth, height: newHeight } = entry.contentRect

      if (wState.isMaximized || wState.isMinimized) return

      _windowWidth = newWidth
      _windowHeight = newHeight
    }, 16) // ~60fps throttle

    const observer = new ResizeObserver(handleResize)
    observer.observe(windowEl)

    return () => observer.disconnect()
  })
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  bind:this={windowEl}
  onclick={() => appsStore.toggleActiveState(app.id, true)}
  class="absolute flex flex-1 flex-col overflow-hidden rounded-t-lg bg-[#1E2028] shadow-md {wState.isMinimized || appWindow.isHidden ? 'invisible pointer-events-none' : ''}"
  style={windowStyles}
>
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="toolbar flex h-8 select-none items-center justify-between bg-[#16171C]"
      onpointerdown={onPointerDown}
      onpointermove={onPointerMove}
      onpointerup={onPointerUp}
    >
      <div class="mr-5 flex h-full max-w-96 items-center truncate px-2 text-sm">{title ?? '-'}</div>
      <div class="flex h-full items-center">
        {#if windowActions.isMinimizable}
          <button
            class="flex h-full w-12 items-center justify-center text-neutral-500 hover:bg-white hover:bg-opacity-5 hover:text-white"
            type="button"
            aria-label="Minimize"
            onclick={(e) => { e.preventDefault(); minimize() }}
          >
            <i class="fa-solid fa-minus text-xs"></i>
          </button>
        {/if}
        {#if windowActions.isMaximizable}
          <button
            class="flex h-full w-12 items-center justify-center text-neutral-500 hover:bg-white hover:bg-opacity-5 hover:text-white"
            type="button"
            aria-label="Maximize"
            onclick={(e) => { e.preventDefault(); maximize() }}
          >
            <i
              class="fa-solid text-xs"
              class:fa-window-restore={wState.isMaximized}
              class:fa-window-maximize={!wState.isMaximized}
            ></i>
          </button>
        {/if}
        {#if windowActions.isClosable}
          <button
            class="flex h-full w-12 items-center justify-center text-neutral-500 hover:bg-red-600 hover:text-white"
            type="button"
            aria-label="Close"
            onclick={(e) => { e.preventDefault(); close() }}
          >
            <i class="fa-solid fa-xmark text-xs"></i>
          </button>
        {/if}
      </div>
    </div>

    {#if isLoading}
      <div class="flex flex-1 items-center justify-center overflow-hidden">
        <ProgressSpinner />
      </div>
    {/if}
    <div class="relative flex flex-1 overflow-hidden" class:hidden={isLoading}>
      {#if app.isInternal}
        <InternalAppComponent
          {app}
          {metadata}
          {appReady}
          {changeWindowTitle}
        />
      {:else}
        <IframeAppComponent
          {app}
          {metadata}
          {appReady}
          {changeWindowTitle}
        />
      {/if}
    </div>
  </div>
