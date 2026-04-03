<script lang="ts">
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import ActiveAppButton from './ActiveAppButton.svelte'

  function toggleStates(id: string) {
    const window = appsStore.windows[id]

    if (window.state.isMinimized) {
      appsStore.toggleMinimizeState(id, false)
      appsStore.toggleActiveState(id, true)
      return
    }

    if (!window.state.isActive) {
      appsStore.toggleActiveState(id, true)
      return
    }

    appsStore.toggleActiveState(id, false)
    appsStore.toggleMinimizeState(id, true)
  }
</script>

<div class="z-10 flex flex-1 gap-1 py-1">
  {#each appsStore.shownWindows as appWindow (appWindow.app.id)}
    <ActiveAppButton
      windowState={appWindow.state}
      id={appWindow.app.id}
      icon={appWindow.app.icon}
      name={appWindow.app.name}
      isActive={appWindow.state.isActive && !appWindow.state.isMinimized}
      onclick={() => toggleStates(appWindow.app.id)}
    />
  {/each}
</div>
