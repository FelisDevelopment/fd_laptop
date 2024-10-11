export interface WifiNetwork {
  ssid: string
  label: string
  password: string | null
  connected?: boolean
}

export interface ConnectionStatus {
  isConnected: boolean
  connectedTo: WifiNetwork | undefined
  airplaneMode: boolean
  connectedToVpn: boolean
}
