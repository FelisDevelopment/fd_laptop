<script lang="ts">
  import type { AppType } from '$lib/types/app.types'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { iconUrl } from '$lib/utils/url.utils'
  import { clickOutside } from '$lib/utils/clickOutside'
  import Avatar from '$lib/components/Avatar.svelte'
  import ContextMenu from '$lib/components/ContextMenu.svelte'

  let { isOpen = false, parent, onclose }: {
    isOpen?: boolean
    parent?: HTMLDivElement
    onclose?: () => void
  } = $props()

  let selectedApp = $state<string | undefined>()
  let contextMenuRef = $state<ContextMenu | undefined>()

  let contextMenuItems = $derived([
    {
      label: localeStore.t('create_shortcut_label'),
      command: () => {
        appsStore.addDesktopIcon(selectedApp!)
        onclose?.()
      }
    }
  ])

  function openContextMenu(event: MouseEvent, id: string) {
    event.stopPropagation()
    event.preventDefault()

    if (!parent || !contextMenuRef) return
    if (!appsStore.apps.find((app) => app.id === id)) return

    selectedApp = id

    const bounds = parent.getBoundingClientRect()

    contextMenuRef.show({
      x: event.clientX - bounds.left,
      y: event.clientY - bounds.top
    })
  }

  function openApp(app: AppType) {
    appsStore.open(app.id)
    onclose?.()
  }

  function signOut() {
    onclose?.()
    laptopStore.close(true)
  }

  function openSettings(tab?: string) {
    onclose?.()
    appsStore.open('settings', { tab: tab || undefined })
  }
</script>

<div>
{#if isOpen}
  <div
    class="absolute bottom-16 left-0 flex h-96 overflow-hidden rounded-xl bg-[#1E2028] shadow-xl"
    use:clickOutside={{ callback: () => onclose?.(), ignore: ['#start-menu-button'] }}
  >
    <div class="flex flex-col justify-between px-2 py-3">
      <Avatar
        image={settingsStore.profilePicture}
        icon={settingsStore.profilePicture ? undefined : 'fa-solid fa-user'}
        onclick={() => openSettings('profile')}
      />
      <div class="flex flex-col gap-1">
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div
          onclick={() => openSettings()}
          class="group relative cursor-pointer rounded-lg p-2 text-gray-400 transition-colors hover:bg-white/10 active:bg-white/15"
        >
          <i class="fa-solid fa-gear text-sm"></i>
        </div>
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div
          onclick={signOut}
          class="group relative cursor-pointer rounded-lg p-2 text-gray-400 transition-colors hover:bg-white/10 active:bg-white/15"
        >
          <i class="fa-solid fa-right-from-bracket text-sm"></i>
        </div>
      </div>
    </div>

    <div class="my-3 w-px bg-gray-600/60"></div>

    <div class="flex min-w-56 flex-col py-3 pr-1">
      <div
        class="flex w-full flex-1 flex-col gap-2 overflow-y-auto px-2 scrollbar-thin scrollbar-track-rounded-[100px] scrollbar-thumb-rounded-[100px] scrollbar-corner-rounded-[100px] scrollbar-track-gray-500/80 scrollbar-thumb-gray-400/80"
      >
        {#each appsStore.userApps as category}
          <div class="flex flex-col">
            <span class="mb-1 ml-3 text-[11px] font-medium uppercase tracking-wide text-gray-400">{category.letter}</span>
            {#each category.data as app}
              <button
                type="button"
                onclick={() => openApp(app)}
                oncontextmenu={(e) => openContextMenu(e, app.id)}
                class="group relative flex items-center gap-2.5 rounded-lg px-3 py-1.5 transition-colors hover:bg-white/10 focus:outline-none active:bg-white/15"
              >
                {#if app.icon}
                  <img class="h-5 w-5" src={iconUrl(app.icon)} alt={app.name} />
                {:else}
                  <i class="fa-solid fa-question h-5 w-5 text-center text-xs text-gray-400"></i>
                {/if}
                <span class="text-[13px] text-gray-100">{app.name}</span>
              </button>
            {/each}
          </div>
        {/each}
      </div>
    </div>
  </div>
{/if}

<ContextMenu
  bind:this={contextMenuRef}
  items={contextMenuItems}
  onhide={() => selectedApp = undefined}
/>
</div>
