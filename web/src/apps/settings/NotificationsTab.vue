<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useEventBus, watchDebounced } from '@vueuse/core'
import { useSettings } from '../../stores/settings.store'
import { onMounted } from 'vue'
import ToggleButton from 'primevue/togglebutton'
import { useLocale } from '../../stores/locale.store'

const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()
const settings = useSettings()
const locale = useLocale()
const bus = useEventBus('settings')

watchDebounced(
  () => settings.doNotDisturb,
  () => bus.emit('updated'),
  { debounce: 500 }
)

onMounted(() => {
  props.changeWindowTitle(locale.t('settings_notifications_title'))
})
</script>
<template>
  <div class="flex flex-1 flex-col items-center justify-start gap-5 overflow-auto">
    <div
      class="flex w-full items-center justify-between rounded-lg bg-gray-300 px-2 py-2 dark:bg-gray-800"
    >
      <div class="flex w-2/3 flex-col">
        <span class="text-sm font-semibold text-color">{{
          locale.t('settings_notifiations_form_title')
        }}</span>
        <span class="break-words text-xs text-muted-color">
          {{ locale.t('settings_notifiations_form_description') }}
        </span>
      </div>
      <ToggleButton
        class="w-24"
        v-model="settings.doNotDisturb"
        :onLabel="locale.t('settings_notifications_on_label')"
        :offLabel="locale.t('settings_notifications_off_label')"
        size="small"
      />
    </div>
  </div>
</template>
