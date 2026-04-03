interface NuiEventData<T> {
  action: string
  data: T
}

export function onNuiEvent<T>(event: string, callback: (data: T) => void): () => void {
  const handler = (payload: MessageEvent<NuiEventData<T>>) => {
    const { action, data } = payload.data
    if (action !== event) return

    callback(data)
  }

  window.addEventListener('message', handler)

  return () => window.removeEventListener('message', handler)
}
