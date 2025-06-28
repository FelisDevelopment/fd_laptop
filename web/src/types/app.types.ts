import type { Component, ComputedGetter, Ref } from 'vue'
import type { WindowDefaultStates, WindowDimensions } from './window.types'

export interface App {
  id: string
  name: string
  icon: string
  resourceName?: string
  isInstalled?: boolean
  isInstalling?: boolean
  isDefaultApp?: boolean
  needsUpdate?: boolean
  ignoreInternalLoading?: boolean
  groups?: string[]
  keepAlive?: boolean
  deviceId?: string
  appstore?: AppStoreOptions
  windowActions: AppWindowActions
  windowDimensions?: WindowDimensions
  windowDefaultStates?: WindowDefaultStates
  overrides?: string[]
  onUse?: any
  onUseServer?: any
  onClose?: any
  onCloseServer?: any
}

export interface AppStoreOptions {
  description?: string
  author?: string
  installTime?: number
  images?: Array<string>
}

export interface AppWindowActions {
  isResizable: boolean
  isMaximizable: boolean
  isClosable: boolean
  isMinimizable: boolean
  isDraggable: boolean
}

export interface InternalApp extends App {
  isInternal: true
  component?: Component
}

export interface ExternalApp extends App {
  isInternal: false
  ui: string
}

export interface InstallAppResponse {
  success: boolean
  error?: string
}

export interface RemoveAppResponse {
  success: boolean
  error?: string
}

export interface AppMessage {
  id: string
  message: any
}

export type AppType = InternalApp | ExternalApp
