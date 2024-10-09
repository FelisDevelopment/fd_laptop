import { useDevelopment } from '../stores/development.store'

const development = useDevelopment()

export const iconUrl = (url: string) => {
  if (url.includes('http') || url.includes('nui:')) return url

  if (development.isDevEnv) return `/icons/${url}`

  return `/web/dist/icons/${url}`
}

export const backgroundUrl = (background: string) => {
  if (development.isDevEnv) return `/backgrounds/${background}`

  return `/web/dist/backgrounds/${background}`
}
