<script setup lang="ts">
import { useLocale } from '../../stores/locale.store'
import { useLaptop } from '../../stores/laptop.store'
import Message from 'primevue/message'
import { onMounted } from 'vue'
import type { InternalAppWindowBinds } from '../../types/window.types'

const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()
const laptop = useLaptop()
const locale = useLocale()

onMounted(() => {
  props.changeWindowTitle(locale.t('settings_devices_title'))
})
</script>
<template>
  <div
    class="lscrollbar flex h-full w-full flex-1 flex-col items-center justify-start gap-5 overflow-auto"
  >
    <div
      class="flex w-full items-center gap-3 rounded-lg bg-gray-300 px-3 py-2 dark:bg-gray-800"
      v-for="device in laptop.installedDevices"
      v-if="laptop.installedDevices.length > 0"
    >
      <i class="pi pi-server text-4xl text-muted-color"></i>
      <div class="flex flex-col">
        <span class="text-xs font-semibold text-muted-color">
          {{ locale.t('settings_devices_slot') }}: {{ device.slot }}
        </span>
        <span class="break-words text-base text-color"> {{ device.metadata.deviceLabel }}</span>
      </div>
    </div>
    <Message v-else severity="error" class="w-full">
      {{ locale.t('settings_devices_no_devices') }}
    </Message>
  </div>
</template>
