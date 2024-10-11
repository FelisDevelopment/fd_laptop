---@type table<string, LaptopApp>
return {
    ['app_store'] = {
        id = 'app_store',
        name = 'App Store',
        icon = 'app_store.svg',
        isDefaultApp = true,
        isInternal = true,
        windowDimensions = {
            width = 1000,
            height = 650,
            minWidth = 1000,
            minHeight = 650,
            maxWidth = 1000,
            maxHeight = 650
        },
        windowActions = {
            isResizable = false,
            isMaximizable = false,
            isClosable = true,
            isMinimizable = true,
            isDraggable = true
        }
    }
}
