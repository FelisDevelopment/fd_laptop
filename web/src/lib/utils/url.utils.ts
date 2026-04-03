import { developmentStore } from '$lib/stores/developmentStore.svelte'

const isDev = developmentStore.isDevEnv || import.meta.env.DEV

type AssetType = 'icons' | 'backgrounds'

export const resolveAssetUrl = (path: string, type: AssetType): string => {
  if (path.includes('http') || path.includes('nui:')) return path

  if (isDev) return `/${type}/${path}`

  return `/web/dist/${type}/${path}`
}

export const iconUrl = (url: string) => resolveAssetUrl(url, 'icons')

export const backgroundUrl = (background: string) => resolveAssetUrl(background, 'backgrounds')
