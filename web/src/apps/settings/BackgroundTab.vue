<script setup lang="ts">
import type { AvailableBackground } from '../../types/background.types'
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useApi } from '../../composables/useApi'
import { MockedBackgrounds } from '../../mock/backgrounds.mock'
import { useSettings } from '../../stores/settings.store'
import { onMounted, onUnmounted, ref } from 'vue'
import { useNotifications } from '../../stores/notifications.store'
import { useEventBus } from '@vueuse/core'
import { backgroundUrl } from '../../utils/url.utils'
import Button from 'primevue/button'
import Skeleton from 'primevue/skeleton'
import { useLocale } from '../../stores/locale.store'

interface SavedBackgroundResponse {
  success: boolean
  error?: string
}

const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()

const settings = useSettings()
const locale = useLocale()
const notif = useNotifications()
const bus = useEventBus('settings')

const isLoading = ref<boolean>(true)
const isChanging = ref<boolean>(false)
const backgrounds = ref<AvailableBackground[]>([])
const originalBackground = ref<string>()

onMounted(async () => {
  props.changeWindowTitle(locale.t('settings_background_title'))

  const { data } = await useApi<AvailableBackground[]>(
    `availableBackgrounds`,
    {},
    undefined,
    MockedBackgrounds
  )

  if (!data.value) {
    return
  }

  backgrounds.value = data.value

  isLoading.value = false
})

const resetBackground = () => {
  if (isChanging.value) return

  if (!originalBackground.value) {
    return
  }

  changeBackground(originalBackground.value)
}

const changeBackground = (background: string) => {
  if (isChanging.value) return

  if (!originalBackground.value) {
    originalBackground.value = settings.backgroundImage
  }

  if (originalBackground.value === background) {
    originalBackground.value = undefined
  }

  settings.changeBackground(background)
}

const saveBackground = async () => {
  if (isChanging.value) return
  if (!originalBackground.value) return

  const { data } = await useApi<SavedBackgroundResponse>(
    'saveBackground',
    {
      method: 'POST',
      body: JSON.stringify({ background: settings.backgroundImage })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success } = data.value as SavedBackgroundResponse

  if (!success) {
    notif.show({
      summary: locale.t('settings_background_saving_error_title'),
      detail: locale.t('settings_background_saving_error_description')
    })

    resetBackground()
    return
  }

  notif.show({
    summary: locale.t('settings_background_saving_success_title'),
    detail: locale.t('settings_background_saving_success_description')
  })

  bus.emit('updated')

  originalBackground.value = undefined
}

onUnmounted(() => {
  resetBackground()
})
</script>
<template>
  <div v-if="isLoading" class="lscrollbar mb-2 grid auto-rows-[9rem] grid-cols-3 gap-4">
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
    <Skeleton height="9rem"></Skeleton>
  </div>
  <div v-else class="lscrollbar grid auto-rows-[9rem] grid-cols-3 gap-4 overflow-auto">
    <div
      class="after:content[''] after:height-[9rem] relative col-span-1 aspect-square overflow-hidden rounded-lg after:relative after:w-full hover:cursor-pointer"
      v-for="bg in backgrounds"
      :key="bg.src"
      @click.prevent="changeBackground(bg.src)"
    >
      <div
        class="absolute inset-0 border-4 border-blue-500"
        v-if="settings.backgroundImage === bg.src"
      >
        <div class="absolute bottom-0 right-0 rounded-tl-lg bg-blue-500 pl-2 pr-1 pt-1">
          <div class="flex items-center justify-between gap-2" v-if="originalBackground">
            <Button icon="pi pi-save" @click.stop="saveBackground()" size="small" />
            <Button
              icon="pi pi-refresh"
              @click.stop="resetBackground()"
              severity="secondary"
              size="small"
            />
          </div>
          <i v-else class="pi pi-check text-xs"></i>
        </div>
      </div>
      <img :src="backgroundUrl(bg.src)" alt="" class="h-full w-full object-cover" v-memo="bg.src" />
    </div>
  </div>
</template>
