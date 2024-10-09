<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useLaptop } from '../../stores/laptop.store'
import { onMounted } from 'vue'
import { useLocale } from '../../stores/locale.store'

const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()
const locale = useLocale()
const laptop = useLaptop()

onMounted(() => {
  props.changeWindowTitle(locale.t('settings_information_title'))
})
</script>
<template>
  <div class="flex flex-1 flex-col items-center justify-center">
    <div class="flex w-2/3 flex-col items-center gap-5" v-if="!laptop.needsUpdate">
      <i class="pi pi-info-circle text-4xl"></i>
      <span class="text-center text-color">{{ locale.t('settings_information_uptodate') }}</span>
    </div>
    <div v-else class="flex w-2/3 flex-col items-center gap-5">
      <i class="pi pi-info-circle text-4xl"></i>
      <span class="text-center text-color">
        {{ locale.t('settings_information_needs_update') }}
      </span>
    </div>
  </div>
</template>
