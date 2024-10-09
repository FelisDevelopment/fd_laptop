<script setup lang="ts">
import { iconUrl } from '../../utils/url.utils'
import type { AppType } from '../../types/app.types'
import Button from 'primevue/button'
import { useLocale } from '../../stores/locale.store'

defineProps<{
  app: AppType
}>()
const emits = defineEmits(['openView', 'install', 'remove'])
const locale = useLocale()
</script>
<template>
  <div class="flex gap-3 rounded-lg bg-gray-300 p-4 dark:bg-gray-700">
    <div class="h-16 w-16 flex-shrink-0">
      <img :src="iconUrl(app.icon)" class="object-contain" />
    </div>
    <div class="flex w-1/3 flex-1 flex-col gap-3">
      <div>
        <h3 class="text-lg font-semibold">{{ app.name }}</h3>
        <p class="truncate text-xs text-muted-color">
          {{ app.appstore?.description }}
        </p>
      </div>
      <div class="flex gap-2">
        <Button
          :label="locale.t('app_store_install_button')"
          size="small"
          v-if="!app.isInstalled && !app.isDefaultApp"
          :loading="app.isInstalling"
          :disabled="app.isInstalling"
          @click.prevent="emits('install', app)"
        />
        <Button
          :label="locale.t('app_store_remove_button')"
          size="small"
          v-if="app.isInstalled && !app.isDefaultApp"
          :loading="app.isInstalling"
          :disabled="app.isInstalling"
          @click.prevent="emits('remove', app)"
        />
        <Button
          :label="locale.t('app_store_view_button')"
          size="small"
          @click.prevent="emits('openView', app)"
        />
      </div>
    </div>
    <div class="flex items-start gap-2 py-2" v-if="app.needsUpdate">
      <i
        class="pi pi-download text-red-500"
        v-tooltip.top="locale.t('app_store_new_version_available')"
      ></i>
    </div>
  </div>
</template>
