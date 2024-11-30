<script setup lang="ts">
import type { Window } from '../types/window.types'
import { useApplications } from '../stores/apps.store'
import { useDraggable, useResizeObserver } from '@vueuse/core'
import { computed, onMounted, ref, useTemplateRef, type CSSProperties } from 'vue'
import ProgressSpinner from 'primevue/progressspinner'

import InternalAppComponent from './windows/InternalAppComponent.vue'
import IframeAppComponent from './windows/IframeAppComponent.vue'

const props = defineProps<{
  appWindow: Window
  parent: HTMLDivElement
}>()

const apps = useApplications()

const appWindow = useTemplateRef<HTMLDivElement>('window')
const toolbar = useTemplateRef<HTMLDivElement>('toolbar')

const {
  app,
  app: { windowActions },
  metadata,
  dimensions,
  position: [initialX, initialY],
  state
} = props.appWindow

const { parent } = props

const windowWidth = ref<number>(dimensions.width)
const windowHeight = ref<number>(dimensions.height)

const title = ref(app.name)
const isLoading = ref<boolean>(true)

const { x, y } = useDraggable(appWindow, {
  initialValue: {
    x: initialX!,
    y: initialY!
  },
  containerElement: parent,
  preventDefault: true,
  handle: toolbar,
  disabled: !windowActions.isDraggable,
  onMove() {
    if (state.isMaximized) {
      state.isMaximized = false
    }
  }
})

const windowStyles = computed<CSSProperties>(() => {
  const styles: CSSProperties = {
    top: `${y.value}px`,
    left: `${x.value}px`,
    width: `${windowWidth.value}px`,
    minWidth: `${dimensions.minWidth}px`,
    maxWidth: `${dimensions.maxWidth}px`,
    height: `${windowHeight.value}px`,
    minHeight: `${dimensions.minHeight}px`,
    maxHeight: `${dimensions.maxHeight}px`,
    zIndex: 20
  }

  if (state.isMaximized) {
    styles.inset = `0px`
    styles.width = '100%'
    styles.height = '100%'
    styles.maxHeight = '100%'
    styles.maxWidth = '100%'
  }

  if (!state.isMaximized && windowActions.isResizable) {
    styles.resize = 'both'
  }

  if (state.isActive) {
    styles.zIndex = 40
  }

  return styles
})

const changeWindowTitle = (newTitle: string) => {
  title.value = newTitle
}

const appReady = () => {
  isLoading.value = false
}

const minimize = () => {
  apps.toggleActiveState(app.id, false)
  apps.toggleMinimizeState(app.id, true)
}

const maximize = () => {
  state.isMaximized = !state.isMaximized
}

const close = () => {
  apps.close(app.id)
}

onMounted(async () => {
  useResizeObserver(appWindow, (entries) => {
    const entry = entries[0]
    const { width: newWidth, height: newHeight } = entry.contentRect

    if (state.isMaximized || state.isMinimized) return

    windowWidth.value = newWidth
    windowHeight.value = newHeight
  })

  if (app.ignoreInternalLoading) {
    isLoading.value = false
  }
})
</script>
<template>
  <div
    v-show="!state.isMinimized && !props.appWindow.isHidden"
    ref="window"
    @click.prevent="apps.toggleActiveState(app.id, true)"
    class="absolute flex flex-1 flex-col overflow-hidden rounded-t-lg bg-gray-100/70 shadow-md backdrop-blur-xl dark:bg-gray-800/70"
    :style="windowStyles"
    :class="{ 'z-[100]': !state.isActive, 'z-[999]': state.isActive }"
  >
    <div
      class="toolbar flex h-8 select-none items-center justify-between bg-gray-100/50 dark:bg-gray-900/50"
      ref="toolbar"
    >
      <div class="mr-5 flex h-full max-w-96 items-center truncate px-2">{{ title ?? '-' }}</div>
      <div class="flex h-full items-center">
        <button
          v-if="windowActions.isMinimizable"
          class="flex h-full w-12 items-center justify-center text-neutral-500"
          :class="['hover:bg-white hover:bg-opacity-5 hover:text-white']"
          type="button"
          @click.prevent="minimize()"
        >
          <i class="pi pi-minus text-xs"></i>
        </button>
        <button
          v-if="windowActions.isMaximizable"
          class="flex h-full w-12 items-center justify-center text-neutral-500"
          :class="['hover:bg-white hover:bg-opacity-5 hover:text-white']"
          type="button"
          @click.prevent="maximize()"
        >
          <i
            class="pi text-xs"
            :class="state.isMaximized ? 'pi-window-minimize' : 'pi-window-maximize'"
          ></i>
        </button>
        <button
          v-if="windowActions.isClosable"
          @click.prevent="close()"
          class="flex h-full w-12 items-center justify-center text-neutral-500 hover:bg-red-600 hover:text-white"
          type="button"
        >
          <i class="pi pi-times text-xs"></i>
        </button>
      </div>
    </div>

    <div v-if="isLoading" class="flex flex-1 items-center justify-center overflow-hidden">
      <ProgressSpinner />
    </div>
    <div class="relative flex flex-1 overflow-hidden" v-show="!isLoading">
      <InternalAppComponent
        v-if="app.isInternal"
        :app="app"
        :metadata="metadata"
        :appReady="appReady"
        :changeWindowTitle="changeWindowTitle"
        class="flex flex-1 overflow-hidden"
      />
      <IframeAppComponent
        v-else
        :app="app"
        :metadata="metadata"
        :appReady="appReady"
        :changeWindowTitle="changeWindowTitle"
        class="flex flex-1 overflow-hidden"
      />
    </div>
  </div>
</template>
