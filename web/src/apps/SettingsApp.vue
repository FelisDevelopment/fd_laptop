<script setup lang="ts">
import { useLocale } from '../stores/locale.store'
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
const locale = useLocale()

const currentTab = ref<AvailableTabs>('wifi')
const tabs: Record<AvailableTabs, TabData> = {
  wifi: {
    icon: 'pi pi-wifi',
    label: locale.t('settings_wifi_tab_label'),
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppWifiTab" */
        import('../apps/settings/WifiTab.vue')
    )
  },
  notifications: {
    icon: 'pi pi-bell',
    label: locale.t('settings_notifications_tab_label'),
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppNotificationsTab" */
        import('../apps/settings/NotificationsTab.vue')
    )
  },
  background: {
    icon: 'pi pi-image',
    label: locale.t('settings_background_tab_label'),
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppBackgroundTab" */
        import('../apps/settings/BackgroundTab.vue')
    )
  },
  appearance: {
    icon: 'pi pi-palette',
    label: locale.t('settings_appearance_tab_label'),
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppApperanceTab" */
        import('../apps/settings/ApperanceTab.vue')
    )
  },
  profile: {
    icon: 'pi pi-user',
    label: locale.t('settings_profile_tab_label'),
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppProfileTab" */
        import('../apps/settings/ProfileTab.vue')
    )
  },
  devices: {
    icon: 'pi pi-server',
    label: locale.t('settings_devices_tab_label'),
    component: defineAsyncComponent(
      () =>
        /* webpackChunkName: "SettingsAppDevicesTab" */
        import('../apps/settings/DevicesTab.vue')
    )
  },
  information: {
    icon: 'pi pi-info-circle',
    label: locale.t('settings_system_information_tab_label'),
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
    <div class="flex w-1/3 flex-col bg-white/50 dark:bg-gray-800/50">
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
      class="w-2/3 bg-gray-50/50 p-4 dark:bg-gray-700/50"
    ></component>
  </div>
</template>
