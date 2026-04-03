class DevelopmentStore {
  daylight = $state<boolean>(false)

  get isDevEnv(): boolean {
    return !(window as any).invokeNative
  }

  applyDevelopmentStyles() {
    if (!this.isDevEnv) return
    this.applyStyles()
  }

  toggleDaylight() {
    if (!this.isDevEnv) return
    this.daylight = !this.daylight
    this.applyStyles()
  }

  applyStyles() {
    if (!this.isDevEnv) return

    const root = document.documentElement

    const bg = this.daylight
      ? 'https://i.imgur.com/VngeNJc.png'
      : 'https://i.imgur.com/34qKung.png'

    root.style.backgroundColor = 'transparent'
    root.style.backgroundImage = `url("${bg}")`
    root.style.backgroundSize = 'cover'
    root.style.backgroundRepeat = 'no-repeat'
    root.style.backgroundPosition = 'center'
    root.style.width = '100%'
    root.style.height = '100%'
  }
}

export const developmentStore = new DevelopmentStore()
