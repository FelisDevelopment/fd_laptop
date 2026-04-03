<script lang="ts">
  import type { WindowStates } from '$lib/types/window.types'
  import { iconUrl } from '$lib/utils/url.utils'
  import { tooltip } from '$lib/utils/tooltip'

  let { id, icon, name, isActive, windowState, onclick }: {
    id: string
    icon: string
    name: string
    isActive: boolean
    windowState: WindowStates
    onclick?: () => void
  } = $props()

  let activeClass = $derived(isActive && !windowState.isMinimized ? 'bg-[#252730]' : '')
</script>

<button
  class="hover-scale top-shadow pointer-events-auto relative flex h-12 w-14 items-center justify-center rounded-lg px-2 transition-colors hover:bg-white/10 {activeClass}"
  use:tooltip={name}
  {onclick}
>
  <img src={iconUrl(icon)} class="h-8 w-8" alt="" />
  {#if isActive && !windowState.isMinimized}
    <div
      class="absolute bottom-0.5 left-1/2 h-[3px] w-[30%] -translate-x-1/2 transform rounded-full bg-blue-500"
    ></div>
  {/if}
</button>
