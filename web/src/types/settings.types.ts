export interface Settings {
  isDarkMode: boolean
  backgroundImage: string
  notificationsEnabled: boolean
}

export interface UserSettings {
  isDarkMode: boolean
  isDoNotDisturb: boolean
  username: string
  profilePicture?: string
  backgroundImage?: string
}

export interface UserSettingsEvent {
  background: string
  dark_mode: boolean
  username: string
  profile_picture: string
}

export interface UpdateProfileEvent {
  username: string
  profilePicture: string
}
