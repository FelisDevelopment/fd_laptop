export interface WifiNetwork {
  ssid: string
  label: string
  password: string | null
  connected?: boolean
}
