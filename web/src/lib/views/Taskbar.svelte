<script lang="ts">
  import StartMenu from './taskbar/StartMenu.svelte'
  import ActiveApps from './taskbar/ActiveApps.svelte'
  import TaskbarBlock from './taskbar/TaskbarBlock.svelte'

  let { parent }: { parent: HTMLDivElement } = $props()
</script>

<div
  id="start-menu"
  class="fixed inset-x-0 bottom-3 z-50 mx-5 flex h-14 flex-none select-none px-2 before:absolute before:inset-0 before:z-0 before:rounded-2xl before:bg-[#1E2028] before:shadow-lg"
>
  <StartMenu {parent} />
  <div class="z-10 mx-1 my-3 w-px bg-gray-600/60"></div>
  <ActiveApps />
  <div class="z-10 mx-1 my-3 w-px bg-gray-600/60"></div>
  <TaskbarBlock />
</div>
