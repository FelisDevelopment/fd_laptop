<script setup lang="ts">
import type { AppType, InstallAppResponse, RemoveAppResponse } from '../types/app.types'
import type { InternalAppWindowBinds } from '../types/window.types'
import { useApplications } from '../stores/apps.store'
import { computed, defineAsyncComponent, onMounted, ref } from 'vue'
import { useApi } from '../composables/useApi'
import { useNotifications } from '../stores/notifications.store'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import InputText from 'primevue/inputtext'
import { useLocale } from '../stores/locale.store'

const AppComponent = defineAsyncComponent(() => import('./appStore/AppComponent.vue'))
const AppViewOverlayComponent = defineAsyncComponent(
  () => import('./appStore/AppViewOverlayComponent.vue')
)

const locale = useLocale()
const applications = useApplications()
const notyf = useNotifications()
const props = defineProps<InternalAppWindowBinds>()

const overlayShown = ref<boolean>(false)
const overlayApp = ref<AppType>()

const openView = (app: AppType) => {
  overlayApp.value = app
  overlayShown.value = true
}

const closeView = () => {
  overlayApp.value = undefined
  overlayShown.value = false
}

const filter = ref<string>()
const filteredApps = computed(() => {
  if (!filter.value) {
    return applications.appStoreApplications
  }

  return applications.appStoreApplications.filter((app) =>
    app.name?.toLowerCase().includes(filter.value!.toLowerCase())
  )
})

const installApp = async (app: AppType) => {
  if (app.isInstalled) {
    return
  }

  app.isInstalling = true

  const { data } = await useApi<InstallAppResponse>(
    'installApp',
    {
      method: 'POST',
      body: JSON.stringify({
        id: app.id
      })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success, error } = data.value as InstallAppResponse

  if (!success) {
    app.isInstalling = false

    notyf.show({
      summary: locale.t('app_store_unable_to_install'),
      detail: error || locale.t('app_store_unable_to_install_helptext')
    })
    return
  }
}

const removeApp = async (app: AppType) => {
  if (!app.isInstalled) {
    return
  }

  app.isInstalling = true

  const { data } = await useApi<RemoveAppResponse>(
    'uninstallApp',
    {
      method: 'POST',
      body: JSON.stringify({
        id: app.id
      })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success, error } = data.value as RemoveAppResponse

  app.isInstalling = false

  if (!success) {
    notyf.show({
      summary: locale.t('app_store_unable_to_remove'),
      detail: error || locale.t('app_store_unable_to_remove_helptext')
    })
    return
  }

  notyf.show({
    summary: locale.t('app_store_uninstall_success'),
    detail: locale.t('app_store_uninstall_success_helptext')
  })

  applications.markAsUninstalled(app.id)
}

onMounted(() => {
  props.appReady()
  props.changeWindowTitle(locale.t('app_store_title'))
})
</script>
<template>
  <div
    class="relative flex flex-1 select-none flex-col gap-4 bg-gray-100 p-4 hover:bg-emphasis dark:bg-gray-800"
  >
    <AppViewOverlayComponent
      v-if="overlayShown"
      :app="overlayApp!"
      @close="closeView"
      @install="installApp"
      @remove="removeApp"
    />
    <div class="flex h-10 items-center justify-between">
      <h2 class="text-3xl font-semibold">{{ locale.t('app_store_title') }}</h2>
      <IconField>
        <InputIcon class="pi pi-search" />
        <InputText v-model="filter" placeholder="Search" type="text" class="rounded-full" />
      </IconField>
    </div>
    <div
      v-if="filteredApps.length > 0"
      class="grid flex-1 grid-cols-2 grid-rows-[repeat(3,min-content)_1fr] gap-3 overflow-auto scrollbar-thin scrollbar-track-rounded-[100px] scrollbar-thumb-rounded-[100px] scrollbar-corner-rounded-[100px] dark:scrollbar-track-gray-500/80 dark:scrollbar-thumb-gray-400/80"
    >
      <AppComponent
        :app="app"
        v-for="app in filteredApps"
        @open-view="openView"
        @install="installApp"
        @remove="removeApp"
      />
    </div>
    <div v-else class="flex flex-1 items-center justify-center">
      <div>
        <h1 class="mt-3 text-2xl font-semibold text-gray-800 md:text-3xl dark:text-white">
          {{ locale.t('app_store_nothing_here') }}
        </h1>
        <p class="mt-4 text-gray-500 dark:text-gray-400">
          {{ locale.t('app_store_nothing_here_helptext') }}
        </p>
      </div>
    </div>
  </div>
</template>
