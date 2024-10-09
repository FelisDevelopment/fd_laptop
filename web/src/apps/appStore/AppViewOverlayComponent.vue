<script setup lang="ts">
import { iconUrl } from '../../utils/url.utils'
import type { AppType } from '../../types/app.types'
import { computed } from 'vue'
import Button from 'primevue/button'
import Galleria from 'primevue/galleria'
import { useLocale } from '../../stores/locale.store'

const props = defineProps<{
  app: AppType
}>()
const emits = defineEmits(['close', 'install', 'remove'])
const locale = useLocale()

const images = computed(() =>
  props.app.appstore?.images
    ? props.app.appstore.images.map((i) => ({
        src: i,
        alt: 'Preview image'
      }))
    : []
)
</script>
<template>
  <div
    class="lscrollbar absolute inset-0 z-50 overflow-auto bg-gray-200/80 backdrop-blur dark:bg-gray-800/80"
  >
    <div
      class="w-full bg-red-700/70 py-3 text-center font-semibold text-white backdrop-blur"
      v-if="app.needsUpdate"
    >
      {{ locale.t('app_store_new_version_available_overlay') }}
    </div>

    <div
      class="relative flex h-44 items-center justify-between bg-gray-300/80 px-10 dark:bg-gray-700/80"
    >
      <Button
        class="absolute right-2 top-2"
        icon="pi pi-times"
        size="small"
        rounded
        outlined
        aria-label="Close"
        @click.prevent="emits('close')"
      />
      <div class="flex flex-1 items-center justify-between gap-5">
        <img :src="iconUrl(app.icon)" class="h-20 w-20" />
        <div class="flex flex-1 flex-col gap-1">
          <h2 class="text-xl font-semibold">{{ app.name }}</h2>
          <span class="break-words text-muted-color">
            {{ app.appstore?.description }}
          </span>
        </div>
        <Button
          label="Install"
          v-if="!app.isInstalled && !app.isDefaultApp"
          :loading="app.isInstalling"
          :disabled="app.isInstalling"
          @click.prevent="emits('install', app)"
        />
        <Button
          label="Remove"
          v-if="app.isInstalled && !app.isDefaultApp"
          :loading="app.isInstalling"
          :disabled="app.isInstalling"
          @click.prevent="emits('remove', app)"
        />
      </div>
    </div>
    <div class="flex flex-col gap-10 px-10 py-5">
      <div class="flex flex-col gap-2">
        <span class="font-semibold text-color">{{
          locale.t('app_store_overlay_description')
        }}</span>
        <p class="text-muted-color">
          {{ app.appstore?.description }}
        </p>
      </div>

      <div class="flex flex-col gap-2" v-if="images.length > 0">
        <span class="font-semibold text-color">{{ locale.t('app_store_overlay_preview') }}</span>
        <Galleria
          :value="images"
          :numVisible="5"
          containerStyle="max-width: 740px"
          :showThumbnails="false"
          :showIndicators="true"
        >
          <template #item="slotProps">
            <img
              :src="slotProps.item.src"
              :alt="slotProps.item.alt"
              style="width: 100%; display: block"
            />
          </template>
        </Galleria>
      </div>
    </div>
  </div>
</template>
