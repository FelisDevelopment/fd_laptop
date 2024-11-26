<script setup lang="ts">
import { useApplications } from '../stores/apps.store'
import { computed, ref, useTemplateRef } from 'vue'
import { GridLayout, GridItem } from 'vue3-grid-layout-next'
import { iconUrl } from '../utils/url.utils'
import { useLocale } from '../stores/locale.store'
import ContextMenu from 'primevue/contextmenu'

const props = defineProps<{
  parent: HTMLDivElement
}>()

const app = useApplications()
const locale = useLocale()
const activeItem = ref<string>()
const desktopRef = useTemplateRef<any>('desktop')

const selectedApp = ref<string>()
const contextMenu = useTemplateRef<any>('contextMenu')
const contextMenuItems = computed(() => [
  {
    label: locale.t('remove_shortcut_label'),
    command: () => {
      app.removeDesktopIcon(selectedApp.value!)
    }
  }
])

const openContextMenu = (event: MouseEvent, id: string) => {
  event.stopPropagation()
  event.preventDefault()

  if (!props.parent) return
  if (!contextMenu.value) return

  const bounds = props.parent.getBoundingClientRect()

  const newEventData = {
    pageX: event.pageX - bounds.left,
    pageY: event.pageY - bounds.top,
    stopPropagation: () => {},
    preventDefault: () => {}
  }

  selectedApp.value = id

  contextMenu.value.show(newEventData)
}

const cols = computed(() => {
  if (!desktopRef.value) return 16

  return Math.floor(desktopRef.value.clientWidth / 96)
})

const appName = computed(() => (id: string) => {
  return app.apps.find((a) => a.id === id)?.name
})

const appIcon = computed(() => (id: string) => {
  return app.apps.find((a) => a.id === id)?.icon
})
</script>
<template>
  <div class="desktop-icons z-10 h-full w-full overflow-hidden" ref="desktop">
    <grid-layout
      :layout="app.filteredDesktopApps"
      :col-num="cols"
      :max-rows="app.desktopRows"
      :row-height="112"
      :is-draggable="true"
      :is-resizable="false"
      :is-mirrored="false"
      :is-bounded="true"
      :vertical-compact="false"
      :margin="[2, 2]"
      :use-css-transforms="true"
      style="width: 100%; height: 100%"
      @mouseup.prevent="activeItem = undefined"
    >
      <grid-item
        v-for="item in app.filteredDesktopApps"
        :x="item.x"
        :y="item.y"
        :w="item.w"
        :h="item.h"
        :i="item.i"
        :key="item.i"
        style="touch-action: none"
      >
        <div
          class="app z-500 flex h-28 w-24 select-none flex-col items-center justify-center rounded-sm border border-transparent hover:bg-white hover:bg-opacity-10 focus:bg-blue-500 focus:bg-opacity-10"
          :class="{ 'bg-blue-500 bg-opacity-10 hover:bg-blue-500': activeItem === item.i }"
          @mouseup.stop="activeItem = item.i"
          @dblclick.stop="app.open(item.appId)"
          @contextmenu.stop="openContextMenu($event, item.appId)"
        >
          <img :src="iconUrl(appIcon(item.appId)!)" width="43" height="43" />
          <span class="app-name text-center text-xs text-white">{{ appName(item.appId) }}</span>
        </div>
      </grid-item>
    </grid-layout>

    <ContextMenu
      ref="contextMenu"
      :model="contextMenuItems"
      :append-to="parent"
      @before-hide="selectedApp = undefined"
    />
  </div>
</template>

<style lang="scss">
.desktop-icons {
  .app {
    .app-name {
      color: #fafafa;
      margin: 4px 0;
      text-shadow: 0 0 4px rgba(0, 0, 0, 0.6);
    }
  }

  .vue-grid-item {
    cursor: auto !important;
  }

  .vue-grid-item.vue-grid-placeholder {
    background: #ceceff !important;
  }
}
</style>
