<script lang="ts">
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { backgroundUrl } from '$lib/utils/url.utils'
  import Window from './Window.svelte'
  import Taskbar from './Taskbar.svelte'
  import Desktop from './Desktop.svelte'
  import Toast from '$lib/components/Toast.svelte'
  import LockScreen from './LockScreen.svelte'

  let laptopRef = $state<HTMLDivElement | null>(null)

  let shouldBeShown = $derived(notificationsStore.shouldBeShown(laptopStore.isOpen, settingsStore.doNotDisturb))

  let styles = $derived.by(() => {
    if (!laptopStore.isOpen && !shouldBeShown) {
      return ''
    }

    return `background-image: url(${backgroundUrl(settingsStore.backgroundImage!)})`
  })

  let dynamicClasses = $derived.by(() => {
    const classes: string[] = ['-translate-x-1/2']

    if (laptopStore.isOpen) {
      classes.push('left-1/2', 'top-1/2', '-translate-y-1/2', 'opacity-50', 'hover:opacity-100', 'transition-opacity', 'duration-300', 'ease-out')
    }

    if (!laptopStore.isOpen && shouldBeShown) {
      classes.push('left-1/2', '-bottom-[75%]', 'hd:-bottom-[70%]')
    }

    return classes.join(' ')
  })

  function handleKeyUp(e: KeyboardEvent) {
    if (e.key === 'Escape' && laptopStore.isOpen && !laptopStore.isLocked) {
      laptopStore.close(true)
    }
  }
</script>

<svelte:window onkeyup={handleKeyUp} />

<div
  id="laptop"
  bind:this={laptopRef}
  class="fixed flex h-[85vh] min-h-[642px] w-[80vw] min-w-[1134px] flex-1 transform overflow-hidden rounded-xl border-8 border-gray-900 bg-[#16171C] bg-cover bg-center shadow-lg outline outline-1 -outline-offset-[1px] outline-gray-700/20 text-gray-100 hd:h-[80vh] hd:max-w-[min(1800px,135vh)] {dynamicClasses}"
  style={styles}
>
  {#if laptopStore.isOpen && laptopStore.isLocked}
    <LockScreen />
  {/if}

  <div class="relative overflow-hidden flex h-[calc(100%-1.0rem-3.5rem)] flex-1 {laptopStore.isOpen && !laptopStore.isLocked ? '' : 'invisible pointer-events-none'}">
    {#if laptopRef}
      <Desktop parent={laptopRef} />
    {/if}
    {#each Object.values(appsStore.windows) as appWindow (appWindow.app.id)}
      {#if laptopRef}
        <Window {appWindow} parent={laptopRef} />
      {/if}
    {/each}
  </div>

  {#if laptopRef}
    <div class={laptopStore.isLocked ? 'invisible pointer-events-none' : ''}>
      <Taskbar parent={laptopRef} />
    </div>
  {/if}

  <Toast
    position={shouldBeShown ? 'top-center' : 'bottom-right'}
  />
</div>
