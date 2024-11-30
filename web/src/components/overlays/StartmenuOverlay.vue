<script setup lang="ts">
import type { AppType } from '../../types/app.types'
import { useSettings } from '../../stores/settings.store'
import { useApplications } from '../../stores/apps.store'
import { onClickOutside } from '@vueuse/core'
import { computed, ref, useTemplateRef } from 'vue'
import { useLaptop } from '../../stores/laptop.store'
import { iconUrl } from '../../utils/url.utils'
import ContextMenu from 'primevue/contextmenu'
import Avatar from 'primevue/avatar'
import { useLocale } from '../../stores/locale.store'

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  parent: {
    type: HTMLDivElement
  }
})

const overlay = ref<HTMLDivElement>()
const emit = defineEmits(['close'])
const apps = useApplications()
const settings = useSettings()
const laptop = useLaptop()
const locale = useLocale()

const selectedApp = ref<string>()
const contextMenu = useTemplateRef<any>('contextMenu')
const contextMenuItems = computed(() => [
  {
    label: locale.t('create_shortcut_label'),
    command: () => {
      apps.addDesktopIcon(selectedApp.value!)

      emit('close')
    }
  }
])

const openContextMenu = (event: MouseEvent, id: string) => {
  event.stopPropagation()
  event.preventDefault()

  if (!props.parent) return
  if (!contextMenu.value) return
  if (!apps.apps.find((app) => app.id === id)) return

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

const openApp = (app: AppType) => {
  apps.open(app.id)
  emit('close')
}

const signOut = () => {
  emit('close')
  laptop.close(true)
}

onClickOutside(
  overlay,
  () => {
    emit('close')
  },
  {
    ignore: ['#start-menu-button']
  }
)

const openSettings = (tab?: string) => {
  emit('close')
  apps.open('settings', { tab: tab || undefined })
}
</script>
<template>
  <div
    v-if="isOpen"
    ref="overlay"
    class="absolute bottom-16 left-0 flex h-96 overflow-hidden rounded-lg bg-gray-100/50 backdrop-blur-xl dark:bg-gray-800/50"
  >
    <div class="flex flex-col justify-between px-2 py-4">
      <Avatar
        v-if="!settings.profilePicture"
        icon="pi pi-user"
        @click.prevent="openSettings('profile')"
        class="hover:cursor-pointer"
      />
      <Avatar
        v-else
        :image="settings.profilePicture"
        @click.prevent="openSettings('profile')"
        class="hover:cursor-pointer"
      />
      <div class="flex flex-col gap-2 hover:cursor-pointer">
        <div
          @click.prevent="openSettings()"
          class="group relative rounded hover:bg-white/50 focus:outline-none active:bg-white/75 dark:hover:bg-black/25 dark:active:bg-black/50"
        >
          <span class="block p-2 transition duration-75 ease-linear active:scale-90">
            <i class="pi pi-cog"></i>
          </span>
        </div>
        <div
          @click.prevent="signOut()"
          class="group relative rounded hover:bg-white/50 focus:outline-none active:bg-white/75 dark:hover:bg-black/25 dark:active:bg-black/50"
        >
          <span class="block p-2 duration-75 active:scale-90">
            <i class="pi pi-sign-out"></i>
          </span>
        </div>
      </div>
    </div>
    <div class="flex min-w-56 bg-gray-200/50 px-2 py-4 dark:bg-gray-900/50">
      <div
        class="flex w-full flex-col gap-3 overflow-y-auto scrollbar-thin scrollbar-track-rounded-[100px] scrollbar-thumb-rounded-[100px] scrollbar-corner-rounded-[100px] dark:scrollbar-track-gray-500/80 dark:scrollbar-thumb-gray-400/80"
      >
        <div class="flex flex-col" v-for="category in apps.userApps">
          <span class="mb-2 ml-5 text-xs">{{ category.letter }}</span>
          <button
            v-for="app in category.data"
            type="button"
            @click="openApp(app)"
            @contextmenu="openContextMenu($event, app.id)"
            class="group relative flex items-center gap-2 rounded px-4 py-1 hover:bg-white/50 focus:outline-none active:bg-white/75 dark:hover:bg-black/25 dark:active:bg-black/50"
          >
            <img v-if="app.icon" class="w-4" :src="iconUrl(app.icon)" :alt="app.name" />
            <i v-else class="pi pi-question w-4 text-xs"></i>
            <span class="text-sm">{{ app.name }}</span>
          </button>
        </div>
      </div>
      <ContextMenu
        ref="contextMenu"
        :model="contextMenuItems"
        :append-to="parent"
        @before-hide="selectedApp = undefined"
      />
    </div>
  </div>
</template>
