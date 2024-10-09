export interface Settings {
  isDarkMode: boolean
  backgroundImage: string
  notificationsEnabled: boolean
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
