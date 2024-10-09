import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { useApi } from '../composables/useApi'
import { useNuiEvent } from '../composables/useNuiEvent'
import { useDevelopment } from './development.store'
import { useApplications } from './apps.store'
import type {
  LaptopCloseEvent,
  LaptopDevice,
  LaptopInitEvent,
  LaptopOpenEvent,
  ServerTimeEvent
} from '../types/laptop.types'
import { useLocale } from './locale.store'

export const useLaptop = defineStore('laptop', () => {
  const development = useDevelopment()
  const locale = useLocale()
  const laptopId = ref<string>()
  const isOpen = ref<boolean>(false)

  const clock24h = ref<boolean>(true)
  const useServerTime = ref<boolean>(false)
  const serverTime = ref<ServerTimeEvent>({
    hour: 0,
    minute: 0
  })
  const dateFormat = ref<string>('MMM DD, YYYY')
  const dateLocale = ref<string>('en-US')
  const locales = ref<Record<string, string>>({})
  const needsUpdate = ref<boolean>(false)

  const installedDevices = ref<LaptopDevice[]>([])

  const formattedServerTime = computed<string>(() => {
    const { hour: currentHour, minute: currentMinute } = serverTime.value
    const prependZero = (value: number) => (value < 10 ? `0${value}` : value)

    const hour = prependZero((currentHour % 24) % 12 || 12)
    const minute = prependZero(currentMinute)

    if (!clock24h.value) {
      return `${hour}:${minute} ${currentHour % 24 < 12 ? 'AM' : 'PM'}`
    }

    return `${hour}:${minute}`
  })

  const init = async () => {
    if (development.isDevEnv) {
      const apps = useApplications()

      await apps.initApps()

      return
    }

    setTimeout(async () => {
      await locale.fetchLocales()
      await useApi('init', {}, undefined, undefined)
    }, 2000)
  }

  const open = (id: string, devices: LaptopDevice[]) => {
    isOpen.value = true
    laptopId.value = id
    installedDevices.value = devices
  }

  const close = async (sendRequest?: boolean) => {
    isOpen.value = false
    laptopId.value = undefined
    installedDevices.value = []

    if (sendRequest) {
      await useApi('close', {}, undefined, undefined)
    }
  }

  const t = (key: string) => locales.value[key] || key

  return {
    t,
    init,
    open,
    close,
    isOpen,
    locales,
    clock24h,
    dateFormat,
    dateLocale,
    serverTime,
    needsUpdate,
    useServerTime,
    installedDevices,
    formattedServerTime
  }
})

useNuiEvent<LaptopInitEvent>('initLaptop', (data: LaptopInitEvent) => {
  const laptop = useLaptop()

  laptop.locales = data.locales
  laptop.useServerTime = data.useServerTime || false
  laptop.clock24h = data.clock24h || false
  laptop.dateFormat = data.dateFormat || 'MMM DD, YYYY'
  laptop.dateLocale = data.dateLocale || 'en-US'
  laptop.needsUpdate = data.needsUpdate || false
})

useNuiEvent<ServerTimeEvent>('updateClock', (data: ServerTimeEvent) => {
  const laptop = useLaptop()

  laptop.serverTime = data
})

useNuiEvent<LaptopOpenEvent>('openLaptop', (data: LaptopOpenEvent) => {
  const laptop = useLaptop()

  laptop.open(data.laptopId, data.devices)
})

useNuiEvent<LaptopCloseEvent>('closeLaptop', () => {
  const laptop = useLaptop()

  laptop.close()
})
