import type { WifiNetwork } from '../types/network.types'
import { useNuiEvent } from '../composables/useNuiEvent'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { useEventBus } from '@vueuse/core'

export const useConnection = defineStore('wifi', () => {
  const airplaneMode = ref<boolean>(false)
  const networks = ref<WifiNetwork[]>([])
  const connectedToVpn = ref<boolean>(false)

  const isConnected = computed<boolean>(() => !!networks.value.find((network) => network.connected))
  const connectedTo = computed<WifiNetwork | undefined>(() =>
    networks.value.find((network) => network.connected)
  )

  const markAsConnected = (ssid: string) => {
    networks.value = networks.value.map((network) => {
      if (network.ssid === ssid) {
        network.connected = true
      }

      if (network.ssid !== ssid && network.connected) {
        network.connected = false
      }

      return network
    })
  }

  const markAsDisconnected = () => {
    networks.value = networks.value.map((network) => {
      network.connected = false

      return network
    })
  }

  const forApps = computed(() => ({
    isConnected: isConnected.value,
    connectedTo: connectedTo.value,
    airplaneMode: airplaneMode.value,
    connectedToVpn: connectedToVpn.value
  }))

  return {
    forApps,
    networks,
    isConnected,
    connectedTo,
    airplaneMode,
    connectedToVpn,
    markAsConnected,
    markAsDisconnected
  }
})

useNuiEvent<WifiNetwork>('addNetwork', (data: WifiNetwork) => {
  const connection = useConnection()

  connection.networks.push(data)
})

useNuiEvent<string>('removeNetwork', (ssid: string) => {
  const connection = useConnection()

  connection.networks = connection.networks.filter((network) => network.ssid !== ssid)
})

useNuiEvent<string>('connect', (ssid: string) => {
  const connection = useConnection()

  connection.markAsConnected(ssid)
})

useNuiEvent<null>('disconnect', () => {
  const connection = useConnection()
  const networkBus = useEventBus('network')

  connection.markAsDisconnected()
  networkBus.emit('updated')
})
