import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useDevelopment } from './development.store'
import { useNuiEvent } from '../composables/useNuiEvent'
import type { UpdateProfileEvent, UserSettings, UserSettingsEvent } from '../types/settings.types'

export const useSettings = defineStore('settings', () => {
  const development = useDevelopment()
  const backgroundImage = ref<string | undefined>('1.jpg')
  const airplaneMode = ref<boolean>(false)
  const doNotDisturb = ref<boolean>(false)
  const isDarkMode = ref<boolean>(true)
  const username = ref<string>('')
  const profilePicture = ref<string>()

  const getBackgroundImage = computed<string>(() => {
    const image = backgroundImage.value || '1.jpg'

    return development.isDevEnv ? `/backgrounds/${image}` : `/web/dist/backgrounds/${image}`
  })

  const toggleNotifications = (state?: boolean): void => {
    doNotDisturb.value = typeof state === 'boolean' ? state : !doNotDisturb.value
  }

  const changeBackground = (image: string): void => {
    backgroundImage.value = image
  }

  const handleDarkModeChange = (): void => {
    if (isDarkMode.value) {
      document.documentElement.classList.add('dark-app')
    } else {
      document.documentElement.classList.remove('dark-app')
    }
  }

  const forApps = computed<UserSettings>(() => ({
    isDarkMode: isDarkMode.value,
    isDoNotDisturb: doNotDisturb.value,
    username: username.value,
    profilePicture: profilePicture.value,
    backgroundImage: backgroundImage.value
  }))

  watch(isDarkMode, () => {
    handleDarkModeChange()
  })

  return {
    forApps,
    username,
    isDarkMode,
    airplaneMode,
    doNotDisturb,
    profilePicture,
    backgroundImage,
    changeBackground,
    getBackgroundImage,
    toggleNotifications
  }
})

useNuiEvent<UserSettingsEvent>('updateSettings', (data: UserSettingsEvent) => {
  const { background, dark_mode, username, profile_picture } = data
  const settings = useSettings()

  settings.isDarkMode = dark_mode
  settings.backgroundImage = background
  settings.username = username
  settings.profilePicture = profile_picture
})

useNuiEvent<UpdateProfileEvent>('updateProfile', (data: UpdateProfileEvent) => {
  const { username, profilePicture } = data
  const settings = useSettings()

  settings.username = username
  settings.profilePicture = profilePicture
})
