import { fetchApi } from '$lib/utils/api'
import { MockedApps } from '../../mock/apps.mock'
import { hasAppComponent, getAppComponent } from '../../apps/apps'
import type { AppType } from '$lib/types/app.types'
import type { Window } from '$lib/types/window.types'
import { DefaultApps } from '$lib/data/defaultApps.defaults'
import { developmentStore } from '$lib/stores/developmentStore.svelte'
import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
import { laptopStore } from '$lib/stores/laptopStore.svelte'
import { localeStore } from '$lib/stores/localeStore.svelte'
import { settingsStore } from '$lib/stores/settingsStore.svelte'
import { onNuiEvent } from '$lib/utils/nuiEvent'
import { appActions, windowDimensions } from '$lib/utils/window.utils'
import { groupApps } from '$lib/utils/app.utils'

export interface DesktopApp {
  appId: string
  x: number
  y: number
  w: number
  h: number
  i: string
}

class AppsStore {
  apps = $state<AppType[]>([])
  windows = $state<Record<string, Window>>({})
  desktopApps = $state<DesktopApp[]>([])
  desktopRows = $state<number>(9)
  lastPosition = $state<[number, number]>([0, 0])

  get appsById(): Map<string, AppType> {
    return new Map(this.apps.map(app => [app.id, app]))
  }

  async initApps(payload?: AppType[]) {
    this.apps = []
    this.windows = {}

    if (developmentStore.isDevEnv) {
      const data = await fetchApi<AppType[]>(
        'apps',
        { method: 'GET' },
        MockedApps
      )

      if (data) this.apps = data
    } else if (payload) {
      this.apps = payload
    }

    const defaultApps = DefaultApps

    this.apps.push(...defaultApps)

    this.apps = this.apps.filter((app: AppType) => {
      if (app.isInternal && !hasAppComponent(app.id)) {
        return false
      }
      return true
    })
  }

  nextFreeCell(occupied: Set<string>): { x: number; y: number } {
    let x = 0, y = 0
    while (occupied.has(`${x},${y}`)) {
      y++
      if (y >= this.desktopRows) { y = 0; x++ }
    }
    return { x, y }
  }

  fixOutOfBoundsApps() {
    if (this.desktopRows <= 0 || this.desktopApps.length === 0) return

    const occupied = new Set<string>(
      this.desktopApps
        .filter(a => a.y < this.desktopRows)
        .map(a => `${a.x},${a.y}`)
    )

    let changed = false

    for (const app of this.desktopApps) {
      if (app.y >= this.desktopRows) {
        const { x, y } = this.nextFreeCell(occupied)
        occupied.add(`${x},${y}`)
        app.x = x
        app.y = y
        changed = true
      }
    }

    if (changed) {
      this.saveDesktopApps()
    }
  }

  addDesktopIcon(id: string) {
    if (!this.apps.find((app) => app.id === id)) return
    if (this.desktopApps.find((app) => app.appId === id)) return

    const occupied = new Set(this.desktopApps.map(a => `${a.x},${a.y}`))
    const { x, y } = this.nextFreeCell(occupied)

    this.desktopApps.push({
      appId: id,
      x,
      y,
      w: 1,
      h: 1,
      i: `${id}`
    })

    this.saveDesktopApps()
  }

  removeDesktopIcon(id: string) {
    this.desktopApps = this.desktopApps.filter((app) => app.appId !== id)
    this.saveDesktopApps()
  }

  addNewApp(app: AppType) {
    if (app.isInternal && !hasAppComponent(app.id)) {
      throw new Error('Internal app component not found')
    }

    const exists = this.apps.find((a) => a.id === app.id)
    const existingIndex = this.apps.findIndex((a) => a.id === app.id)

    if (exists?.isInstalled) {
      app.isInstalled = true
    }

    if (this.windows[app.id]) {
      delete this.windows[app.id]
    }

    if (existingIndex > -1) {
      this.apps.splice(existingIndex, 1, app)
    } else {
      this.apps.push(app)
    }
  }

  removeApp(id: string) {
    this.apps = this.apps.filter((app: AppType) => app.id !== id)

    if (this.windows[id]) {
      delete this.windows[id]
    }
  }

  get filteredDesktopApps() {
    const appsMap = this.appsById
    const installedDeviceIds = new Set(
      laptopStore.installedDevices.map(d => d.metadata.deviceId)
    )

    return this.desktopApps.filter((desktopApp) => {
      const app = appsMap.get(desktopApp.appId)
      if (!app) return false

      if (app.groups && !app.groups.includes(settingsStore.job!)) {
        return false
      }

      const hasDeviceAccess = app.deviceId && installedDeviceIds.has(app.deviceId)
      const isAccessible = app.isInstalled || app.isDefaultApp || hasDeviceAccess
      const hasJobGroup = settingsStore.job && app.groups?.includes(settingsStore.job)

      return isAccessible || hasJobGroup
    })
  }

  get userApps() {
    const installedDeviceIds = new Set(
      laptopStore.installedDevices.map(d => d.metadata.deviceId)
    )

    return groupApps(
      this.apps.filter((app: AppType) => {
        if (app.groups && !app.groups.includes(settingsStore.job!)) {
          return false
        }

        const hasDeviceAccess = app.deviceId && installedDeviceIds.has(app.deviceId)
        return app.isInstalled || app.isDefaultApp || hasDeviceAccess
      })
    )
  }

  toggleActiveState(id: string, state: boolean) {
    if (!this.windows[id]) return

    if (this.windows[id].state.isActive === state) return

    if (state) {
      Object.values(this.windows).forEach((window) => {
        window.state.isActive = false
      })
    }

    this.windows[id].state.isActive = state
  }

  toggleMinimizeState(id: string, isMinimized?: boolean) {
    if (!this.windows[id]) return

    this.windows[id].state.isMinimized =
      typeof isMinimized === 'boolean' ? isMinimized : !this.windows[id].state.isMinimized
  }

  windowPosition(): [number, number] {
    this.lastPosition = [this.lastPosition[0] + 20, this.lastPosition[1] + 20]

    const [x, y] = this.lastPosition

    if (x > 100 || y > 100) {
      this.lastPosition = [20, 20]
    }

    return this.lastPosition
  }

  async open(id: string, data?: Record<string, any>) {
    let app = this.apps.find((app: AppType) => app.id === id)

    if (!app?.isInstalled && !app?.isDefaultApp && !app?.deviceId) {
      notificationsStore.show({
        summary: localeStore.t('open_app_not_found_title'),
        detail: localeStore.t('open_app_not_found_description')
      })
      return
    }

    if (
      app.deviceId &&
      !laptopStore.installedDevices.find((d) => d.metadata.deviceId === app.deviceId)
    ) {
      return
    }

    if (this.windows[id] && this.windows[id].app.keepAlive && this.windows[id].isHidden) {
      this.windows[id].isHidden = false
      return
    }

    if (this.windows[id]) {
      notificationsStore.show({
        summary: localeStore.t('open_already_open_title'),
        detail: localeStore.t('open_already_open_description')
      })
      return
    }

    if (app.isInternal && !app.component) {
      const component = await getAppComponent(app.id)
      if (component) {
        app.component = component
      }
    }

    app.windowActions = appActions(app)

    this.windows[id] = {
      state: {
        isMaximized: app.windowDefaultStates?.isMaximized || false,
        isMinimized: app.windowDefaultStates?.isMinimized || false,
        isActive: false
      },
      app: app,
      dimensions: windowDimensions(app),
      position: this.windowPosition(),
      metadata: data || undefined
    }

    this.toggleActiveState(id, true)
  }

  close(id: string) {
    if (!this.windows[id]) return

    if (this.windows[id].app.keepAlive) {
      this.windows[id].isHidden = true
      return
    }

    delete this.windows[id]
  }

  closeNonKeepAlive() {
    for (const id of Object.keys(this.windows)) {
      if (this.windows[id].app.keepAlive) {
        this.windows[id].isHidden = true
      } else {
        delete this.windows[id]
      }
    }
  }

  get appStoreApplications() {
    return this.apps.filter((app: AppType) => app.appstore)
  }

  markAsInstalled(id: string) {
    const app = this.apps.find((app: AppType) => app.id === id)
    if (!app) return

    app.isInstalled = true
    app.isInstalling = false
  }

  markAsUninstalled(id: string) {
    const app = this.apps.find((app: AppType) => app.id === id)
    if (!app) return

    app.isInstalled = false
    app.isInstalling = false

    if (this.windows[id]) {
      this.close(id)
    }
  }

  get shownWindows() {
    return Object.values(this.windows).filter((window) => !window.isHidden)
  }

  populateDefaultDesktopApps() {
    const defaultApps = this.apps.filter(app => app.isOnDesktopByDefault)
    const occupied = new Set(this.desktopApps.map(a => `${a.x},${a.y}`))

    for (const app of defaultApps) {
      const { x, y } = this.nextFreeCell(occupied)
      occupied.add(`${x},${y}`)

      this.desktopApps.push({
        appId: app.id,
        x,
        y,
        w: 1,
        h: 1,
        i: `${app.id}`
      })
    }

    if (this.desktopApps.length > 0) {
      this.saveDesktopApps()
    }
  }

  saveDesktopApps() {
    fetchApi('saveDesktopApps', {
      method: 'POST',
      body: JSON.stringify({
        desktopApps: this.desktopApps
      })
    })
  }
}

export const appsStore = new AppsStore()

onNuiEvent<AppType[]>('initApps', (payload) => {
  appsStore.initApps(payload)
})

onNuiEvent<AppType>('newApp', (payload) => {
  appsStore.addNewApp(payload)
})

onNuiEvent<string>('removeApp', (payload) => {
  appsStore.removeApp(payload)
})

onNuiEvent<string>('appInstalled', (payload) => {
  appsStore.markAsInstalled(payload)
})

onNuiEvent<string>('requestAppClosing', (payload) => {
  appsStore.close(payload)
})

onNuiEvent<DesktopApp[]>('desktopApps', (payload) => {
  const occupied = new Set<string>()
  for (const app of payload) {
    const key = `${app.x},${app.y}`
    if (occupied.has(key)) {
      const { x, y } = appsStore.nextFreeCell(occupied)
      app.x = x
      app.y = y
      occupied.add(`${x},${y}`)
    } else {
      occupied.add(key)
    }
  }

  appsStore.desktopApps = payload

  if (payload.length === 0) {
    appsStore.populateDefaultDesktopApps()
  } else {
    appsStore.fixOutOfBoundsApps()
  }
})
