import type { Notification } from '$lib/types/notification.types'
import { onNuiEvent } from '$lib/utils/nuiEvent'
import { settingsStore } from '$lib/stores/settingsStore.svelte'

export interface ToastItem {
  id: number
  summary: string
  detail: string
  life: number
  group: string
}

class NotificationsStore {
  private notificationTimeoutId: ReturnType<typeof setTimeout> | undefined
  hasNewNotification = $state<boolean>(false)
  notifications = $state<Notification[]>([])
  toasts = $state<ToastItem[]>([])
  private nextToastId = 0

  get hasNotifications(): boolean {
    return this.notifications.length > 0
  }

  shouldBeShown(isLaptopOpen: boolean, doNotDisturb: boolean): boolean {
    if (isLaptopOpen) return false
    if (doNotDisturb) return false
    if (!this.hasNewNotification) return false
    return true
  }

  show(data: Omit<Notification, 'time'>) {
    this.notifications.push({
      summary: data.summary,
      detail: data.detail,
      time: new Date()
    })

    if (this.notificationTimeoutId) clearTimeout(this.notificationTimeoutId)
    this.hasNewNotification = true
    this.notificationTimeoutId = setTimeout(() => {
      this.hasNewNotification = false
      this.notificationTimeoutId = undefined
    }, 4000)

    if (settingsStore.doNotDisturb) return

    const toastId = this.nextToastId++
    const life = data.life ?? 4000

    this.toasts.push({
      id: toastId,
      summary: data.summary,
      detail: data.detail,
      life,
      group: 'headless'
    })

    setTimeout(() => {
      this.removeToast(toastId)
    }, life)
  }

  removeToast(id: number) {
    this.toasts = this.toasts.filter((t) => t.id !== id)
  }

  close(index: number) {
    this.notifications.splice(index, 1)
  }

  clear() {
    this.toasts = []
    this.notifications = []
  }
}

export const notificationsStore = new NotificationsStore()

onNuiEvent<Notification>('newNotification', (data) => {
  notificationsStore.show(data)
})
