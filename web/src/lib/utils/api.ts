import { parentResourceName } from '$lib/utils/parentResource.utils'
import { developmentStore } from '$lib/stores/developmentStore.svelte'

export async function fetchApi<T>(
  url: string,
  options?: RequestInit,
  mockData?: T
): Promise<T | null> {
  if (!parentResourceName && !mockData) {
    throw new Error('No mock data provided for development environment')
  }

  if (mockData && developmentStore.isDevEnv) {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(mockData)
      }, 500)
    })
  }

  if (!parentResourceName) {
    throw new Error('Unable to access window object or GetParentResourceName method')
  }

  const resolvedUrl = `https://${parentResourceName}/${url}`

  const response = await fetch(resolvedUrl, options)
  let data = await response.text()

  if (!data) return null

  try {
    return JSON.parse(data) as T
  } catch {
    return data as unknown as T
  }
}
