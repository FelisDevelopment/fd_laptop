import { developmentStore } from '$lib/stores/developmentStore.svelte'
import { localeStore } from '$lib/stores/localeStore.svelte'
import { appsStore } from '$lib/stores/appsStore.svelte'
import { fetchApi } from '$lib/utils/api'
import { onNuiEvent } from '$lib/utils/nuiEvent'
import type {
  LaptopCloseEvent,
  LaptopDevice,
  LaptopInitEvent,
  LaptopOpenEvent,
  ServerTimeEvent
} from '$lib/types/laptop.types'

class LaptopStore {
  laptopId = $state<string | undefined>()
  isOpen = $state<boolean>(false)
  isLocked = $state<boolean>(false)
  hasPassword = $state<boolean>(false)
  clock24h = $state<boolean>(true)
  useServerTime = $state<boolean>(false)
  serverTime = $state<ServerTimeEvent>({ hour: 0, minute: 0 })
  dateFormat = $state<string>('MMM dd, yyyy')
  dateLocale = $state<string>('en-US')
  locales = $state<Record<string, string>>({})
  needsUpdate = $state<boolean>(false)
  showDeviceAppsInStore = $state<boolean>(false)
  installedDevices = $state<LaptopDevice[]>([])

  get formattedServerTime(): string {
    const { hour: currentHour, minute: currentMinute } = this.serverTime
    const pad = (n: number) => n.toString().padStart(2, '0')
    const minute = pad(currentMinute)
    const h = currentHour % 24

    if (this.clock24h) {
      return `${pad(h)}:${minute}`
    }

    return `${pad(h % 12 || 12)}:${minute} ${h < 12 ? 'AM' : 'PM'}`
  }

  async init() {
    if (developmentStore.isDevEnv) {
      await appsStore.initApps()
      await localeStore.fetchLocales()
      return
    }

    setTimeout(async () => {
      await localeStore.fetchLocales()
      await fetchApi('init', {})
    }, 2000)
  }

  open(id: string, devices: LaptopDevice[], hasPassword?: boolean) {
    this.isOpen = true
    this.laptopId = id
    this.installedDevices = devices
    this.hasPassword = hasPassword || false
    this.isLocked = this.hasPassword
  }

  unlock() {
    this.isLocked = false
  }

  async close(sendRequest?: boolean) {
    this.isOpen = false
    this.laptopId = undefined
    this.installedDevices = []

    if (sendRequest) {
      await fetchApi('close', {})
    }
  }

  t = (key: string) => this.locales[key] || key
}

export const laptopStore = new LaptopStore()

onNuiEvent<LaptopInitEvent>('initLaptop', (data) => {
  laptopStore.locales = data.locales
  laptopStore.useServerTime = data.useServerTime || false
  laptopStore.clock24h = data.clock24h || false
  laptopStore.dateFormat = data.dateFormat || 'MMM dd, yyyy'
  laptopStore.dateLocale = data.dateLocale || 'en-US'
  laptopStore.showDeviceAppsInStore = data.showDeviceAppsInStore || false
  laptopStore.needsUpdate = data.needsUpdate || false
})

onNuiEvent<ServerTimeEvent>('updateClock', (data) => {
  laptopStore.serverTime = data
})

onNuiEvent<LaptopOpenEvent>('openLaptop', (data) => {
  laptopStore.open(data.laptopId, data.devices, data.hasPassword)
})

onNuiEvent<LaptopCloseEvent>('closeLaptop', () => {
  laptopStore.close()
})
