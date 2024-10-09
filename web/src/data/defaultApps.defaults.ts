import type { AppType } from '../types/app.types'

export const DefaultApps: AppType[] = [
  {
    id: 'settings',
    name: 'Settings',
    icon: 'settings.svg',
    isDefaultApp: true,
    isInternal: true,
    windowActions: {
      isResizable: false,
      isMaximizable: false,
      isClosable: true,
      isMinimizable: true,
      isDraggable: true
    },
    windowDimensions: {
      width: 750,
      height: 550,
      maxWidth: 750,
      maxHeight: 550,
      minHeight: 550,
      minWidth: 750
    }
  }
]
