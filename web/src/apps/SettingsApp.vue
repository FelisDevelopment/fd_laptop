<script setup lang="ts">
import type { InternalAppWindowBinds } from '../types/window.types'
import { defineAsyncComponent, onMounted, ref, type Component } from 'vue'

type AvailableTabs =
  | 'wifi'
  | 'notifications'
  | 'background'
  | 'appearance'
  | 'information'
  | 'profile'
  | 'devices'

type TabData = {
  icon: string
  label: string
  component: Component
}

const props = defineProps<Omit<InternalAppWindowBinds, 'app'>>()

const currentTab = ref<AvailableTabs>('wifi')
const tabs: Record<AvailableTabs, TabData> = {
  wifi: {
    icon: 'pi pi-wifi',
    label: 'Wi-Fi',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppWifiTab" */
        import('../apps/settings/WifiTab.vue')
    )
  },
  notifications: {
    icon: 'pi pi-bell',
    label: 'Notifications',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppNotificationsTab" */
        import('../apps/settings/NotificationsTab.vue')
    )
  },
  background: {
    icon: 'pi pi-image',
    label: 'Background',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppBackgroundTab" */
        import('../apps/settings/BackgroundTab.vue')
    )
  },
  appearance: {
    icon: 'pi pi-palette',
    label: 'Appearance',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppApperanceTab" */
        import('../apps/settings/ApperanceTab.vue')
    )
  },
  profile: {
    icon: 'pi pi-user',
    label: 'Profile',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppProfileTab" */
        import('../apps/settings/ProfileTab.vue')
    )
  },
  devices: {
    icon: 'pi pi-server',
    label: 'Devices',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppDevicesTab" */
        import('../apps/settings/DevicesTab.vue')
    )
  },
  information: {
    icon: 'pi pi-info-circle',
    label: 'System Information',
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppInformationTab" */
        import('../apps/settings/InformationTab.vue')
    )
  }
}

const switchTab = (tab: AvailableTabs) => {
  if (tab === currentTab.value) return
  currentTab.value = tab
}

onMounted(() => {
  props.appReady()

  if (props.metadata?.tab) {
    switchTab(props.metadata.tab)
  }
})
</script>
<template>
  <div class="flex flex-1 select-none overflow-hidden">
    <div class="flex w-1/3 flex-col bg-white dark:bg-gray-800">
      <div
        class="hover:text- flex cursor-pointer items-center gap-3 px-4 py-3 text-sm text-muted-color"
        :class="{
          'bg-emphasis dark:bg-highlight-emphasis': currentTab === key,
          'hover:bg-emphasis hover:text-color': currentTab !== key
        }"
        v-for="(tab, key) in tabs"
        @click.stop="switchTab(key)"
      >
        <i :class="tab.icon"></i>
        {{ tab.label }}
      </div>
    </div>
    <component
      :is="tabs[currentTab].component"
      :changeWindowTitle="changeWindowTitle"
      class="w-2/3 bg-gray-50 p-4 dark:bg-gray-700"
    ></component>
  </div>
</template>
