import type { AppType } from './app.types'

export interface WindowDimensions {
  width: number
  minWidth: number
  maxWidth: number
  height: number
  minHeight: number
  maxHeight: number
}

export interface WindowStates {
  isMaximized: boolean
  isMinimized: boolean
  isActive: boolean
}

export interface WindowDefaultStates {
  isMaximized?: boolean
  isMinimized?: boolean
}

export interface Window {
  state: WindowStates
  app: AppType
  dimensions: WindowDimensions
  position: [number, number]
  metadata?: Record<string, any>
  isHidden?: boolean
}

export interface InternalAppWindowBinds<T = unknown> {
  app: T
  metadata?: Record<string, any> | undefined
  appReady: () => void
  changeWindowTitle: (newTitle: string) => void
}
