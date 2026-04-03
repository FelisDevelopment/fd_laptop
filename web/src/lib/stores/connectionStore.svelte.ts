import type { ConnectionStatus, WifiNetwork } from '$lib/types/network.types'
import { onNuiEvent } from '$lib/utils/nuiEvent'
import { networkBus } from '$lib/utils/eventBus'

class ConnectionStore {
  airplaneMode = $state<boolean>(false)
  networks = $state<WifiNetwork[]>([])
  connectedToVpn = $state<boolean>(false)

  get isConnected(): boolean {
    return !!this.networks.find((network) => network.connected)
  }

  get connectedTo(): WifiNetwork | undefined {
    return this.networks.find((network) => network.connected)
  }

  get forApps(): ConnectionStatus {
    return {
      isConnected: this.isConnected,
      connectedTo: this.connectedTo !== undefined ? JSON.parse(JSON.stringify(this.connectedTo)) : undefined,
      airplaneMode: this.airplaneMode,
      connectedToVpn: this.connectedToVpn
    }
  }

  markAsConnected(ssid: string) {
    this.networks = this.networks.map((network) => {
      if (network.ssid === ssid) {
        network.connected = true
      }
      if (network.ssid !== ssid && network.connected) {
        network.connected = false
      }
      return network
    })
  }

  markAsDisconnected() {
    this.networks = this.networks.map((network) => {
      network.connected = false
      return network
    })
  }
}

export const connectionStore = new ConnectionStore()

onNuiEvent<WifiNetwork>('addNetwork', (data) => {
  connectionStore.networks.push(data)
})

onNuiEvent<string>('removeNetwork', (ssid) => {
  const oldLength = connectionStore.networks.length
  connectionStore.networks = connectionStore.networks.filter((network) => network.ssid !== ssid)

  if (oldLength !== connectionStore.networks.length) {
    networkBus.emit('updated')
  }
})

onNuiEvent<string>('connect', (ssid) => {
  connectionStore.markAsConnected(ssid)
})

onNuiEvent<null>('disconnect', () => {
  connectionStore.markAsDisconnected()
  networkBus.emit('updated')
})
