import { useEventListener } from '@vueuse/core'

interface NuiEventData<T> {
  action: string
  data: T
}

export const useNuiEvent = <T>(event: string, callback: (data: T) => void) => {
  const handler = (payload: MessageEvent<NuiEventData<T>>) => {
    const { action, data } = payload.data
    if (action !== event) return

    callback(data)
  }

  useEventListener(window, 'message', handler)
}
