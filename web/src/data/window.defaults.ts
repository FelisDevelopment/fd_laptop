import type { AppWindowActions } from '../types/app.types'
import type { WindowDimensions } from '../types/window.types'

export const defaultAppWindowActions: AppWindowActions = {
  isResizable: true,
  isMaximizable: true,
  isClosable: true,
  isMinimizable: true,
  isDraggable: true
}

export const defaultDimensions: WindowDimensions = {
  width: 700,
  minWidth: 500,
  maxWidth: 1000,
  height: 600,
  minHeight: 500,
  maxHeight: 1000
}
