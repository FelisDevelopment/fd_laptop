import type { AppType, AppWindowActions } from '../types/app.types'
import { defaultAppWindowActions, defaultDimensions } from '../data/window.defaults'
import type { WindowDimensions } from '@/types/window.types'

export const appActions = (app: AppType) => {
  const defaultActions = defaultAppWindowActions

  if (!app.windowActions) {
    app.windowActions = defaultActions

    return app.windowActions
  }

  for (const [key, value] of Object.entries(defaultActions) as [keyof AppWindowActions, any][]) {
    if (app.windowActions[key] === undefined) {
      app.windowActions[key] = value
    }
  }

  return app.windowActions
}

export const windowDimensions = (app: AppType): WindowDimensions => {
  const defaultWindowDimesions = defaultDimensions

  if (!app.windowDimensions) {
    return defaultWindowDimesions
  }

  for (const [key, value] of Object.entries(defaultWindowDimesions) as [
    keyof WindowDimensions,
    any
  ][]) {
    if (app.windowDimensions[key] === undefined) {
      app.windowDimensions[key] = value
    }
  }

  return app.windowDimensions
}
