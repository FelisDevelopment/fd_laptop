import { useApi } from '../composables/useApi'
import { MockedApps } from '../mock/apps.mock'
import { defineStore, type _UnwrapAll } from 'pinia'
import { computed, ref } from 'vue'
import { apps as internalAppsComponents } from '../apps/apps'
import type { AppType } from '../types/app.types'
import type { Window } from '../types/window.types'
import { DefaultApps } from '../data/defaultApps.defaults'
import { useDevelopment } from './development.store'
import { useNuiEvent } from '../composables/useNuiEvent'
import { useNotifications } from './notifications.store'
import { appActions, windowDimensions } from '../utils/window.utils'
import { groupApps } from '../utils/app.utils'
import { useLaptop } from './laptop.store'
import { useLocale } from './locale.store'

export const useApplications = defineStore('applications', () => {
  const development = useDevelopment()
  const notyf = useNotifications()
  const laptop = useLaptop()
  const locale = useLocale()
  const apps = ref<AppType[]>([])
  const windows = ref<Record<string, Window>>({})
  const lastPosition = ref<[number, number]>([0, 0])

  const initApps = async (payload?: AppType[]) => {
    apps.value = []
    windows.value = {}

    if (payload) {
      apps.value = payload
    }

    if (development.isDevEnv) {
      const { data } = await useApi<AppType[]>(
        'apps',
        {
          method: 'GET'
        },
        undefined,
        MockedApps
      )

      if (!data.value) return

      apps.value = data.value
    }

    const defaultApps = DefaultApps

    apps.value.push(...defaultApps)

    apps.value
      .filter((app: AppType) => {
        if (app.isInternal && !internalAppsComponents[app.id]) {
          return false
        }

        return true
      })
      .map((app: AppType) => {
        if (app.isInternal) {
          app.component = internalAppsComponents[app.id]
        }
      })
  }

  const addNewApp = (app: AppType) => {
    if (app.isInternal && !internalAppsComponents[app.id]) {
      throw new Error('Internal app component not found')
    }

    if (app.isInternal) {
      app.component = internalAppsComponents[app.id]
    }
    const exists = apps.value.find((a) => a.id === app.id)
    const existingIndex = apps.value.findIndex((a) => a.id === app.id)

    if (exists?.isInstalled) {
      app.isInstalled = true
    }

    if (windows.value[app.id]) {
      delete windows.value[app.id]
    }

    if (existingIndex > -1) {
      apps.value.splice(existingIndex, 1, app)
    } else {
      apps.value.push(app)
    }
  }

  const removeApp = (id: string) => {
    apps.value = apps.value.filter((app: AppType) => app.id !== id)

    if (windows.value[id]) {
      delete windows.value[id]
    }
  }

  const userApps = computed(() => {
    return groupApps(
      apps.value.filter(
        (app: AppType) =>
          app.isInstalled ||
          app.isDefaultApp ||
          (app.deviceId &&
            laptop.installedDevices.find((d) => d.metadata.deviceId === app.deviceId))
      )
    )
  })

  const toggleActiveState = (id: string, state: boolean) => {
    if (!windows.value[id]) return

    if (windows.value[id].state.isActive === state) return

    if (state) {
      Object.values(windows.value).forEach((window) => {
        window.state.isActive = false
      })
    }

    windows.value[id].state.isActive = state
  }

  const toggleMinimizeState = (id: string, isMinimized?: boolean) => {
    if (!windows.value[id]) return

    windows.value[id].state.isMinimized =
      typeof isMinimized === 'boolean' ? isMinimized : !windows.value[id].state.isMinimized
  }

  const windowPosition = () => {
    lastPosition.value = [lastPosition.value[0] + 20, lastPosition.value[1] + 20]

    const [x, y] = lastPosition.value

    if (x > 100 || y > 100) {
      lastPosition.value = [20, 20]
    }

    return lastPosition.value
  }

  const open = (id: string, data?: Record<string, any>) => {
    let app = apps.value.find((app: AppType) => app.id === id)

    if (!app?.isInstalled && !app?.isDefaultApp && !app?.deviceId) {
      notyf.show({
        summary: locale.t('open_app_not_found_title'),
        detail: locale.t('open_app_not_found_description')
      })
      return
    }

    if (
      app.deviceId &&
      !laptop.installedDevices.find((d) => d.metadata.deviceId === app.deviceId)
    ) {
      return
    }

    if (windows.value[id] && windows.value[id].app.keepAlive && windows.value[id].isHidden) {
      windows.value[id].isHidden = false
      return
    }

    if (windows.value[id]) {
      notyf.show({
        summary: locale.t('open_already_open_title'),
        detail: locale.t('open_already_open_description')
      })
      return
    }

    app.windowActions = appActions(app)

    windows.value[id] = {
      state: {
        isMaximized: app.windowDefaultStates?.isMaximized || false,
        isMinimized: app.windowDefaultStates?.isMinimized || false,
        isActive: false
      },
      app: app,
      dimensions: windowDimensions(app),
      position: windowPosition(),
      metadata: data || undefined
    }

    toggleActiveState(id, true)

    return
  }

  const close = (id: string) => {
    if (!windows.value[id]) return

    if (windows.value[id].app.keepAlive) {
      windows.value[id].isHidden = true
      return
    }

    delete windows.value[id]
  }

  const appStoreApplications = computed(() => {
    return apps.value.filter((app: AppType) => app.appstore)
  })

  const markAsInstalled = (id: string) => {
    const app = apps.value.find((app: AppType) => app.id === id)

    if (!app) return

    app.isInstalled = true
    app.isInstalling = false

    return
  }

  const markAsUninstalled = (id: string) => {
    const app = apps.value.find((app: AppType) => app.id === id)

    if (!app) return

    app.isInstalled = false
    app.isInstalling = false

    if (windows.value[id]) {
      close(id)
    }

    return
  }

  const shownWindows = computed(() => {
    return Object.values(windows.value).filter((window) => !window.isHidden)
  })

  return {
    open,
    close,
    windows,
    initApps,
    userApps,
    addNewApp,
    removeApp,
    shownWindows,
    markAsInstalled,
    markAsUninstalled,
    toggleActiveState,
    toggleMinimizeState,
    appStoreApplications
  }
})

useNuiEvent<AppType[]>('initApps', (payload: AppType[]) => {
  const apps = useApplications()

  apps.initApps(payload)
})

useNuiEvent<AppType>('newApp', (payload: AppType) => {
  const apps = useApplications()

  apps.addNewApp(payload)
})

useNuiEvent<AppType>('newApp', (payload: AppType) => {
  const apps = useApplications()

  apps.addNewApp(payload)
})

useNuiEvent<string>('removeApp', (payload: string) => {
  const apps = useApplications()

  apps.removeApp(payload)
})

useNuiEvent<string>('appInstalled', (payload: string) => {
  const apps = useApplications()

  apps.markAsInstalled(payload)
})
