export interface LaptopInitEvent {
  locales: Record<string, string>
  useServerTime: boolean
  clock24h: boolean
  dateFormat: string
  dateLocale: string
  needsUpdate: boolean
}

export interface ServerTimeEvent {
  hour: number
  minute: number
}

export interface LaptopOpenEvent {
  laptopId: string
  devices: LaptopDevice[]
}

export interface LaptopCloseEvent {}

export interface LaptopDevice {
  slot: number
  metadata: {
    deviceId: string
    deviceLabel: string
    [key: string]: any
  }
}
