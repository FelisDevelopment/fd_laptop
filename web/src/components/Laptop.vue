<script setup lang="ts">
import { useApplications } from '../stores/apps.store'
import { useSettings } from '../stores/settings.store'
import { computed, defineAsyncComponent, useTemplateRef, type CSSProperties } from 'vue'
import DynamicDialog from 'primevue/dynamicdialog'
import { useLaptop } from '../stores/laptop.store'
import { backgroundUrl } from '../utils/url.utils'
import { onKeyUp } from '@vueuse/core'
import { useNotifications } from '../stores/notifications.store'

const Window = defineAsyncComponent(() => import('./Window.vue'))
const Taskbar = defineAsyncComponent(() => import('./Taskbar.vue'))
const Desktop = defineAsyncComponent(() => import('./Desktop.vue'))

const settings = useSettings()
const apps = useApplications()
const notif = useNotifications()
const laptop = useLaptop()

const laptopRef = useTemplateRef<HTMLDivElement>('laptopRef')

const styles = computed<CSSProperties>(() => {
  if (!laptop.isOpen && !notif.shouldBeShown) {
    return {}
  }

  return {
    backgroundImage: `url(${backgroundUrl(settings.backgroundImage!)})`
  }
})

onKeyUp('Escape', () => {
  if (!laptop.isOpen) return

  laptop.close(true)
})
</script>
<template>
  <div
    id="laptop"
    ref="laptopRef"
    class="fixed flex h-[85vh] min-h-[642px] w-[80vw] min-w-[1134px] flex-1 transform overflow-hidden rounded-xl border-8 border-gray-900 bg-white bg-cover bg-center shadow-lg outline outline-1 -outline-offset-[1px] outline-gray-100/20 text-color hd:h-[80vh]"
    :style="styles"
    :class="{
      'left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 opacity-50 hover:opacity-100':
        laptop.isOpen,
      '-bottom-[75%] left-1/2 -translate-x-1/2 hd:-bottom-[70%]':
        !laptop.isOpen && notif.shouldBeShown
    }"
  >
    <div class="relative flex h-[calc(100%-1.0rem-3.5rem)] flex-1" v-show="laptop.isOpen">
      <Desktop v-if="laptop.isOpen && laptopRef" :parent="laptopRef" />
      <Window
        v-if="laptopRef"
        v-for="window in apps.windows"
        :key="window.app.id"
        :appWindow="window"
        :parent="laptopRef"
      />
    </div>

    <Taskbar v-if="laptopRef" :parent="laptopRef" />
    <DynamicDialog appendTo="#laptop" v-if="laptop.isOpen" />
  </div>
</template>
