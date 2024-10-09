<script setup lang="ts">
import { useApplications } from '../stores/apps.store'
import { useSettings } from '../stores/settings.store'
import { computed, defineAsyncComponent, useTemplateRef, type CSSProperties } from 'vue'
import DynamicDialog from 'primevue/dynamicdialog'
import { useLaptop } from '../stores/laptop.store'
import { backgroundUrl } from '../utils/url.utils'
import { onKeyUp } from '@vueuse/core'

const Window = defineAsyncComponent(() => import('./Window.vue'))
const Taskbar = defineAsyncComponent(() => import('./Taskbar.vue'))

const settings = useSettings()
const apps = useApplications()
const laptop = useLaptop()

const laptopRef = useTemplateRef<HTMLDivElement>('laptopRef')

const styles = computed<CSSProperties>(() => {
  if (laptop.isOpen) {
    return {
      backgroundImage: `url(${backgroundUrl(settings.backgroundImage!)})`
    }
  }

  return {}
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
    class="fixed left-1/2 top-1/2 flex h-[85vh] min-h-[642px] w-[80vw] min-w-[1134px] flex-1 -translate-x-1/2 -translate-y-1/2 transform overflow-hidden rounded-xl border-8 border-gray-900 bg-white bg-cover bg-center opacity-50 shadow-lg outline outline-1 -outline-offset-[1px] outline-gray-100/20 text-color hover:opacity-100 hd:h-[80vh]"
    :style="styles"
  >
    <div class="relative flex h-[calc(100%-1.0rem-3.5rem)] flex-1" v-show="laptop.isOpen">
      <Window
        v-if="laptopRef"
        v-for="window in apps.windows"
        :key="window.app.id"
        :appWindow="window"
        :parent="laptopRef"
      />
    </div>

    <Taskbar v-if="laptop.isOpen" />
    <DynamicDialog appendTo="#laptop" v-if="laptop.isOpen" />
  </div>
</template>
