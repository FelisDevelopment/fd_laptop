type Listener<T extends string> = (event: T) => void

class EventBus<T extends string = string> {
  private listeners: Set<Listener<T>> = new Set()

  on(listener: Listener<T>): () => void {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  emit(event: T): void {
    for (const listener of this.listeners) {
      listener(event)
    }
  }

  off(listener: Listener<T>): void {
    this.listeners.delete(listener)
  }
}

type SettingsEvent = 'updated'
type NetworkEvent = 'updated'

export const settingsBus = new EventBus<SettingsEvent>()
export const networkBus = new EventBus<NetworkEvent>()
