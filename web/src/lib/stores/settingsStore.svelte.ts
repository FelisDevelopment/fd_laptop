import { developmentStore } from '$lib/stores/developmentStore.svelte'
import { onNuiEvent } from '$lib/utils/nuiEvent'
import { fetchApi } from '$lib/utils/api'
import { debounce } from '$lib/utils/debounce'
import type { UpdateProfileEvent, UserSettings, UserSettingsEvent } from '$lib/types/settings.types'

class SettingsStore {
  backgroundImage = $state<string | undefined>('1.jpg')
  airplaneMode = $state<boolean>(false)
  doNotDisturb = $state<boolean>(false)
  username = $state<string>('')
  profilePicture = $state<string | undefined>()
  job = $state<string | undefined>()

  get getBackgroundImage(): string {
    const image = this.backgroundImage || '1.jpg'
    return developmentStore.isDevEnv ? `/backgrounds/${image}` : `/web/dist/backgrounds/${image}`
  }

  get forApps(): UserSettings {
    return {
      isDarkMode: true,
      isDoNotDisturb: this.doNotDisturb,
      username: this.username,
      profilePicture: this.profilePicture,
      backgroundImage: this.backgroundImage
    }
  }

  toggleNotifications(state?: boolean): void {
    this.doNotDisturb = typeof state === 'boolean' ? state : !this.doNotDisturb
  }

  changeBackground(image: string): void {
    this.backgroundImage = image
  }

  private debouncedSaveDnd = debounce((newValue: boolean) => {
    fetchApi(
      'setDoNotDisturb',
      {
        method: 'POST',
        body: JSON.stringify({ doNotDisturb: newValue })
      }
    )
  }, 1000)

  private initialized = false

  constructor() {
    $effect.root(() => {
      $effect(() => {
        const dnd = this.doNotDisturb
        if (!this.initialized) {
          this.initialized = true
          return
        }
        this.debouncedSaveDnd(dnd)
      })
    })
  }
}

export const settingsStore = new SettingsStore()

onNuiEvent<UserSettingsEvent>('updateSettings', (data) => {
  const { background, username, profile_picture } = data

  settingsStore.backgroundImage = background
  settingsStore.username = username
  settingsStore.profilePicture = profile_picture
})

onNuiEvent<UpdateProfileEvent>('updateProfile', (data) => {
  const { username, profilePicture } = data

  settingsStore.username = username
  settingsStore.profilePicture = profilePicture
})

onNuiEvent<string>('loadJob', (data) => {
  settingsStore.job = data
})
