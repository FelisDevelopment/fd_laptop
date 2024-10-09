import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

export const useDevelopment = defineStore('development', () => {
  const daylight = ref<boolean>(false)
  const isDevEnv = computed((): boolean => !(window as any).invokeNative)

  const applyDevelopmentStyles = () => {
    if (!isDevEnv.value) return

    applyStyles()
  }

  const toggleDaylight = () => {
    if (!isDevEnv.value) return

    daylight.value = !daylight.value
    applyStyles()
  }

  const applyStyles = () => {
    if (!isDevEnv.value) return

    const root = document.documentElement

    const bg = daylight.value
      ? 'https://i.imgur.com/VngeNJc.png'
      : 'https://i.imgur.com/34qKung.png'

    root!.style.backgroundColor = 'transparent'

    root!.style.backgroundImage = `url("${bg}")`
    root!.style.backgroundSize = 'cover'
    root!.style.backgroundRepeat = 'no-repeat'
    root!.style.backgroundPosition = 'center'

    root!.style.width = '100%'
    root!.style.height = '100%'
  }

  return {
    isDevEnv,
    applyStyles,
    toggleDaylight,
    applyDevelopmentStyles
  }
})
