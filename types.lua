---@meta

---@class WindowDimensions
---@field width? number
---@field height? number
---@field minWidth? number
---@field minHeight? number
---@field maxWidth? number
---@field maxHeight? number

---@class WindowActions
---@field isResizable? boolean
---@field isMaximizable? boolean
---@field isClosable? boolean
---@field isMinimizable? boolean
---@field isDraggable? boolean

---@class WindowDefaultStates
---@field isMaximized boolean
---@field isMinimized boolean

---@class AppStoreOptions
---@field description? string
---@field author? string
---@field installTime? number
---@field images? string[]

---@class LaptopApp
---@field id string
---@field name string
---@field icon string
---@field isDefaultApp boolean
---@field isInstalled? boolean
---@field isInternal? boolean
---@field isReactOrVue? boolean
---@field isAlpine? boolean
---@field overrides? string[]
---@field groups? string[]
---@field deviceId? string
---@field needsUpdate? boolean
---@field resourceName? string
---@field ui? string
---@field appstore? AppStoreOptions
---@field keepAlive? boolean
---@field windowDimensions? WindowDimensions
---@field windowActions? WindowActions
---@field windowDefaultStates? WindowDefaultStates
---@field onUse? function
---@field onUseServer? function
---@field onClose? function
---@field onCloseServer? function

---@class WifiNetwork
---@field ssid string
---@field label string
---@field password? string

---@class WifiConnection: WifiNetwork
---@field connected boolean

---@class LaptopDeviceMetadata
---@field deviceId string
---@field deviceLabel string
---@field [string] any

---@class LaptopDevice
---@field slot number
---@field metadata table<LaptopDeviceMetadata>

---@class UserSettings
---@field background string
---@field dark_mode boolean
---@field username string
---@field profile_picture string
---@field installedApps table<string>

---@class BackgroundSource
---@field src string

---@class Notification
---@field summary string
---@field detail string
