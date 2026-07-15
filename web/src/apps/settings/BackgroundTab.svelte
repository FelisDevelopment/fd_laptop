<script module lang="ts">
  import type { AvailableBackground } from '$lib/types/background.types'

  let cachedBackgrounds: AvailableBackground[] | null = null
  let backgroundsRequest: Promise<AvailableBackground[] | null> | null = null
</script>

<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { fetchApi } from '$lib/utils/api'
  import { MockedBackgrounds } from '../../mock/backgrounds.mock'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { settingsBus } from '$lib/utils/eventBus'
  import { backgroundUrl } from '$lib/utils/url.utils'
  import Skeleton from '$lib/components/Skeleton.svelte'

  interface SavedBackgroundResponse {
    success: boolean
    error?: string
  }

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  let isLoading = $state(cachedBackgrounds === null)
  let isChanging = $state(false)
  let backgrounds = $state<AvailableBackground[]>(cachedBackgrounds ?? [])
  let originalBackground = $state<string | undefined>()

  onMount(async () => {
    changeWindowTitle(localeStore.t('settings_background_title'))

    if (cachedBackgrounds) return

    if (!backgroundsRequest) {
      backgroundsRequest = fetchApi<AvailableBackground[]>(
        'availableBackgrounds',
        {},
        MockedBackgrounds
      )
    }

    const data = await backgroundsRequest

    if (!data) {
      backgroundsRequest = null
      return
    }

    cachedBackgrounds = data
    backgrounds = data
    isLoading = false
  })

  function resetBackground() {
    if (isChanging) return
    if (!originalBackground) return

    changeBackground(originalBackground)
  }

  function changeBackground(background: string) {
    if (isChanging) return

    if (!originalBackground) {
      originalBackground = settingsStore.backgroundImage
    }

    if (originalBackground === background) {
      originalBackground = undefined
    }

    settingsStore.changeBackground(background)
  }

  async function saveBackground() {
    if (isChanging) return
    if (!originalBackground) return

    const data = await fetchApi<SavedBackgroundResponse>(
      'saveBackground',
      {
        method: 'POST',
        body: JSON.stringify({ background: settingsStore.backgroundImage })
      },
      { success: true, error: undefined }
    )

    const { success } = data as SavedBackgroundResponse

    if (!success) {
      notificationsStore.show({
        summary: localeStore.t('settings_background_saving_error_title'),
        detail: localeStore.t('settings_background_saving_error_description')
      })

      resetBackground()
      return
    }

    notificationsStore.show({
      summary: localeStore.t('settings_background_saving_success_title'),
      detail: localeStore.t('settings_background_saving_success_description')
    })

    settingsBus.emit('updated')

    originalBackground = undefined
  }

  onDestroy(() => {
    resetBackground()
  })
</script>

<div class="flex flex-1 flex-col gap-4 overflow-hidden">
  <div class="flex items-center justify-between">
    <h2 class="text-base font-semibold text-[#F0F0F5]">
      {localeStore.t('settings_background_tab_label')}
    </h2>
    {#if originalBackground}
      <div class="flex items-center gap-2">
        <button
          type="button"
          aria-label="Save background"
          class="flex h-8 w-8 items-center justify-center rounded-full bg-[#5BBD6B] text-white shadow-sm transition-colors hover:bg-[#4DAD5D]"
          onclick={() => saveBackground()}
        >
          <i class="fa-solid fa-floppy-disk text-xs"></i>
        </button>
        <button
          type="button"
          aria-label="Reset background"
          class="flex h-8 w-8 items-center justify-center rounded-full bg-[#2D2F3A] text-[#8B8D9A] shadow-sm transition-colors hover:bg-[#3a3c4a]"
          onclick={() => resetBackground()}
        >
          <i class="fa-solid fa-rotate text-xs"></i>
        </button>
      </div>
    {/if}
  </div>

  {#if isLoading}
    <div class="lscrollbar flex-1 min-h-0 overflow-y-auto overflow-x-hidden p-2">
      <div class="grid grid-cols-3 gap-3">
      {#each Array(9) as _}
        <div class="aspect-[5/4]">
          <Skeleton height="100%" />
        </div>
      {/each}
      </div>
    </div>
  {:else}
    <div class="lscrollbar flex-1 min-h-0 overflow-y-auto overflow-x-hidden p-2">
      <div class="grid grid-cols-3 gap-3">
      {#each backgrounds as bg (bg.src)}
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div
          class="group relative cursor-pointer overflow-hidden rounded-xl {settingsStore.backgroundImage === bg.src ? 'ring-[3px] ring-[#7C8AED]' : ''}"
          onclick={() => changeBackground(bg.src)}
        >
          <img src={backgroundUrl(bg.src)} alt="" class="block aspect-[5/4] w-full object-cover" />
          {#if settingsStore.backgroundImage === bg.src && !originalBackground}
            <div class="absolute bottom-1.5 right-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-[#7C8AED]">
              <i class="fa-solid fa-check text-[10px] text-white"></i>
            </div>
          {/if}
        </div>
      {/each}
      </div>
    </div>
  {/if}
</div>
