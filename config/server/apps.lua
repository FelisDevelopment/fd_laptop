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
    },
    ['spellme'] = {
        id = 'spellme',
        name = 'SpellMe',
        icon = 'spellme.svg',
        isDefaultApp = true,
        isInternal = true,
        windowDimensions = {
            width = 500,
            height = 800,
            minWidth = 500,
            minHeight = 800,
            maxWidth = 500,
            maxHeight = 800
        },
        windowActions = {
            isResizable = false,
            isMaximizable = false,
            isClosable = true,
            isMinimizable = true,
            isDraggable = true
        }
    },
    ['calendar'] = {
        id = 'calendar',
        name = 'Calendar',
        icon = 'calendar.svg',
        isDefaultApp = true,
        isInternal = true,
        windowDimensions = {
            width = 500,
            height = 700,
            minWidth = 500,
            minHeight = 700,
            maxWidth = 500,
            maxHeight = 700
        },
        windowActions = {
            isResizable = false,
            isMaximizable = false,
            isClosable = true,
            isMinimizable = true,
            isDraggable = true
        }
    },
    ['notes'] = {
        id = 'notes',
        name = 'Notes',
        icon = 'notes.svg',
        isDefaultApp = true,
        isInternal = true,
        windowDimensions = {
            width = 550,
            height = 600,
            minWidth = 400,
            minHeight = 450,
            maxWidth = 800,
            maxHeight = 900
        },
        windowActions = {
            isResizable = true,
            isMaximizable = true,
            isClosable = true,
            isMinimizable = true,
            isDraggable = true
        }
    },
    ['email'] = {
        id = 'email',
        name = 'Email',
        icon = 'email.svg',
        isDefaultApp = true,
        isInternal = true,
        windowDimensions = {
            width = 750,
            height = 600,
            minWidth = 600,
            minHeight = 500,
            maxWidth = 1000,
            maxHeight = 800
        },
        windowActions = {
            isResizable = true,
            isMaximizable = true,
            isClosable = true,
            isMinimizable = true,
            isDraggable = true
        }
    }
}
