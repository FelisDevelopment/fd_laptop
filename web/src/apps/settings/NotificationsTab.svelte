<script lang="ts">
  import { onMount } from 'svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { settingsBus } from '$lib/utils/eventBus'
  import { debounce } from '$lib/utils/debounce'
  import ToggleSwitch from '$lib/components/ToggleSwitch.svelte'

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  const debouncedEmit = debounce(() => settingsBus.emit('updated'), 500)

  let prevDnd = settingsStore.doNotDisturb
  $effect(() => {
    const val = settingsStore.doNotDisturb
    if (val !== prevDnd) {
      prevDnd = val
      debouncedEmit()
    }
  })

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_notifications_title'))
  })
</script>

<div class="flex flex-1 flex-col gap-4 overflow-auto">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_notifications_tab_label')}
  </h2>

  <div class="rounded-xl bg-[#1E2028]">
    <div class="flex items-center justify-between px-4 py-3">
      <div class="flex items-center gap-3">
        <div class="flex h-7 w-7 items-center justify-center rounded-lg bg-purple-500">
          <i class="fa-solid fa-moon text-xs text-white"></i>
        </div>
        <div class="flex flex-col">
          <span class="text-sm font-medium text-[#F0F0F5]">
            {localeStore.t('settings_notifiations_form_title')}
          </span>
          <span class="text-[11px] text-[#8B8D9A]">
            {localeStore.t('settings_notifiations_form_description')}
          </span>
        </div>
      </div>
      <ToggleSwitch
        bind:checked={settingsStore.doNotDisturb}
        onLabel={localeStore.t('settings_notifications_on_label')}
        offLabel={localeStore.t('settings_notifications_off_label')}
      />
    </div>
  </div>

  <div class="flex flex-1 flex-col items-center justify-center">
    <i class="fa-solid {settingsStore.doNotDisturb ? 'fa-bell-slash' : 'fa-bell'} text-5xl text-[#50525E] opacity-[0.15]"></i>
  </div>
</div>
