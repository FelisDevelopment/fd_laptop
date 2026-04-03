<script lang="ts">
  import { onMount } from 'svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { settingsBus } from '$lib/utils/eventBus'
  import { debounce } from '$lib/utils/debounce'

  interface SavedApperanceResponse {
    success: boolean
    error?: string
  }

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  async function saveApperance() {
    const data = await fetchApi<SavedApperanceResponse>(
      'saveAppearance',
      {
        method: 'POST',
        body: JSON.stringify({ isDarkMode: settingsStore.isDarkMode })
      },
      { success: true, error: undefined }
    )

    const { success } = data as SavedApperanceResponse

    if (!success) {
      notificationsStore.show({
        summary: localeStore.t('settings_apperance_saving_error_title'),
        detail: localeStore.t('settings_apperance_saving_error_description')
      })
      return
    }

    notificationsStore.show({
      summary: localeStore.t('settings_apperance_saving_success_title'),
      detail: localeStore.t('settings_apperance_saving_success_description')
    })

    settingsBus.emit('updated')
  }

  const debouncedSave = debounce(() => saveApperance(), 2000)

  let prevDarkMode = settingsStore.isDarkMode
  $effect(() => {
    const val = settingsStore.isDarkMode
    if (val !== prevDarkMode) {
      prevDarkMode = val
      debouncedSave()
    }
  })

  function selectTheme(dark: boolean) {
    settingsStore.isDarkMode = dark
  }

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_apperance_title'))
  })
</script>

<div class="flex flex-1 flex-col gap-4 overflow-auto">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_apperance_theme_title')}
  </h2>

  <div class="grid grid-cols-2 gap-4">
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="group cursor-pointer rounded-xl border-2 p-3 transition-colors duration-150 {!settingsStore.isDarkMode ? 'border-[#7C8AED]' : 'border-transparent hover:bg-[#252730]'}"
      onclick={() => selectTheme(false)}
    >
      <div class="mb-3 overflow-hidden rounded-lg border border-gray-200 bg-gray-100">
        <div class="flex items-center gap-1.5 border-b border-gray-200 bg-white px-2.5 py-1.5">
          <div class="h-2 w-2 rounded-full bg-red-400"></div>
          <div class="h-2 w-2 rounded-full bg-yellow-400"></div>
          <div class="h-2 w-2 rounded-full bg-green-400"></div>
        </div>
        <div class="flex h-20">
          <div class="flex w-1/3 flex-col gap-1 border-r border-gray-200 bg-gray-50 p-1.5">
            <div class="h-1.5 w-3/4 rounded bg-gray-300"></div>
            <div class="h-1.5 w-1/2 rounded bg-blue-400"></div>
            <div class="h-1.5 w-2/3 rounded bg-gray-300"></div>
          </div>
          <div class="flex flex-1 flex-col gap-1.5 p-2">
            <div class="h-2 w-1/2 rounded bg-gray-300"></div>
            <div class="h-1.5 w-3/4 rounded bg-gray-200"></div>
            <div class="h-1.5 w-2/3 rounded bg-gray-200"></div>
          </div>
        </div>
      </div>
      <div class="flex items-center justify-center gap-2">
        {#if !settingsStore.isDarkMode}
          <i class="fa-solid fa-circle-check text-sm text-[#7C8AED]"></i>
        {/if}
        <span class="text-sm font-medium text-[#F0F0F5]">
          {localeStore.t('settings_apperance_theme_light')}
        </span>
      </div>
    </div>

    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="group cursor-pointer rounded-xl border-2 p-3 transition-colors duration-150 {settingsStore.isDarkMode ? 'border-[#7C8AED]' : 'border-transparent hover:bg-[#252730]'}"
      onclick={() => selectTheme(true)}
    >
      <div class="mb-3 overflow-hidden rounded-lg border border-gray-700 bg-gray-900">
        <div class="flex items-center gap-1.5 border-b border-gray-700 bg-gray-800 px-2.5 py-1.5">
          <div class="h-2 w-2 rounded-full bg-red-400"></div>
          <div class="h-2 w-2 rounded-full bg-yellow-400"></div>
          <div class="h-2 w-2 rounded-full bg-green-400"></div>
        </div>
        <div class="flex h-20">
          <div class="flex w-1/3 flex-col gap-1 border-r border-gray-700 bg-gray-800/50 p-1.5">
            <div class="h-1.5 w-3/4 rounded bg-gray-600"></div>
            <div class="h-1.5 w-1/2 rounded bg-blue-500"></div>
            <div class="h-1.5 w-2/3 rounded bg-gray-600"></div>
          </div>
          <div class="flex flex-1 flex-col gap-1.5 p-2">
            <div class="h-2 w-1/2 rounded bg-gray-600"></div>
            <div class="h-1.5 w-3/4 rounded bg-gray-700"></div>
            <div class="h-1.5 w-2/3 rounded bg-gray-700"></div>
          </div>
        </div>
      </div>
      <div class="flex items-center justify-center gap-2">
        {#if settingsStore.isDarkMode}
          <i class="fa-solid fa-circle-check text-sm text-[#7C8AED]"></i>
        {/if}
        <span class="text-sm font-medium text-[#F0F0F5]">
          {localeStore.t('settings_apperance_theme_dark')}
        </span>
      </div>
    </div>
  </div>

  <p class="text-[11px] text-[#8B8D9A]">
    {localeStore.t('settings_apperance_theme_description')}
  </p>
</div>
