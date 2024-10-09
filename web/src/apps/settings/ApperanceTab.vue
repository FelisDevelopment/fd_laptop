<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useEventBus, watchDebounced } from '@vueuse/core'
import { useSettings } from '../../stores/settings.store'
import { onMounted } from 'vue'
import { useApi } from '../../composables/useApi'
import { useNotifications } from '../../stores/notifications.store'
import ToggleButton from 'primevue/togglebutton'
import { useLocale } from '../../stores/locale.store'

const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()
const settings = useSettings()
const locale = useLocale()
const notif = useNotifications()
const bus = useEventBus('settings')

interface SavedApperanceResponse {
  success: boolean
  error?: string
}

const saveApperance = async () => {
  const { data } = await useApi<SavedApperanceResponse>(
    'saveAppearance',
    {
      method: 'POST',
      body: JSON.stringify({ isDarkMode: settings.isDarkMode })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success } = data.value as SavedApperanceResponse

  if (!success) {
    notif.show({
      summary: locale.t('settings_apperance_saving_error_title'),
      detail: locale.t('settings_apperance_saving_error_description')
    })

    return
  }

  notif.show({
    summary: locale.t('settings_apperance_saving_success_title'),
    detail: locale.t('settings_apperance_saving_success_description')
  })

  bus.emit('updated')
}

watchDebounced<boolean>(
  () => settings.isDarkMode,
  () => {
    saveApperance()
  },
  { debounce: 2000 }
)

onMounted(() => {
  props.changeWindowTitle(locale.t('settings_apperance_title'))
})
</script>
<template>
  <div class="flex flex-1 flex-col items-center justify-start gap-5 overflow-auto">
    <div
      class="flex w-full items-center justify-between rounded-lg bg-gray-300 px-2 py-2 dark:bg-gray-800"
    >
      <div class="flex w-2/3 flex-col">
        <span class="text-sm font-semibold text-color">{{
          locale.t('settings_apperance_theme_title')
        }}</span>
        <span class="break-words text-xs text-muted-color">
          {{ locale.t('settings_apperance_theme_description') }}
        </span>
      </div>
      <ToggleButton
        class="w-24"
        v-model="settings.isDarkMode"
        :onLabel="locale.t('settings_apperance_theme_dark')"
        :offLabel="locale.t('settings_apperance_theme_light')"
        size="small"
      />
    </div>
  </div>
</template>
