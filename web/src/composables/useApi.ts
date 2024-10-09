import { parentResourceName } from '../utils/parentResource.utils'
import { useDevelopment } from '../stores/development.store'
import {
  useFetch,
  type MaybeRefOrGetter,
  type UseFetchOptions,
  type UseFetchReturn
} from '@vueuse/core'
import { ref } from 'vue'

export function useApi<T>(
  url: MaybeRefOrGetter<string>,
  options: RequestInit,
  useFetchOptions?: UseFetchOptions,
  mockData?: T
): UseFetchReturn<T> & PromiseLike<UseFetchReturn<T>> {
  const development = useDevelopment()
  const parentResource = parentResourceName

  if (!parentResource && !mockData) {
    throw new Error('No mock data provided for development environment')
  }

  if (mockData && development.isDevEnv) {
    // @ts-ignore
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({
          data: ref<T>(mockData)
        })
      }, 500)
    })
  }

  if (!parentResource) {
    throw new Error('Unable to access window object or GetParentResourceName method')
  }

  const resolvedUrl = `https://${parentResource}/${url}` as string

  return useFetch(
    resolvedUrl,
    options,
    useFetchOptions || {
      afterFetch(ctx) {
        if (!ctx.data) {
          return ctx
        }

        if (ctx.data && typeof ctx.data === 'string') {
          ctx.data = JSON.parse(ctx.data)
        }

        return ctx
      }
    }
  )
}
