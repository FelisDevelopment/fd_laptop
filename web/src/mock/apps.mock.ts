import type { AppType } from '../types/app.types'

export const MockedApps: AppType[] = [
  {
    id: 'marketplace',
    name: 'Marketplace',
    icon: 'marketplace.png',
    isDefaultApp: true,
    isInternal: true,
    windowDimensions: {
      width: 1000,
      height: 650,
      minWidth: 1000,
      minHeight: 650,
      maxWidth: 1000,
      maxHeight: 650
    },
    windowActions: {
      isResizable: false,
      isMaximizable: false,
      isClosable: true,
      isMinimizable: true,
      isDraggable: true
    }
  }
]
