import { defineStore } from 'pinia'
import { useToast } from '../services/usetoast'
import { computed, ref } from 'vue'
import type { Notification } from '../types/notification.types'
import { useSettings } from './settings.store'
import { useLaptop } from './laptop.store'
import { useNuiEvent } from '../composables/useNuiEvent'

export const useNotifications = defineStore('notifications', () => {
  const settings = useSettings()
  const toast = useToast()
  const laptop = useLaptop()
  const hasNewNotification = ref<number>()
  const notifications = ref<Notification[]>([])

  const shouldBeShown = computed(() => {
    if (laptop.isOpen) return false
    if (settings.doNotDisturb) return false
    if (!hasNewNotification.value) return false

    return true
  })

  const show = (data: Omit<Notification, 'time'>) => {
    notifications.value.push({
      summary: data.summary,
      detail: data.detail,
      time: new Date()
    })

    if (settings.doNotDisturb) return

    if (hasNewNotification.value) clearTimeout(hasNewNotification.value)
    hasNewNotification.value = setTimeout(() => {
      hasNewNotification.value = undefined
    }, 4000)

    toast.add({
      //@ts-ignore
      severity: 'custom',
      summary: data.summary,
      detail: data.detail,
      life: data.life ?? 4000,
      group: 'headless'
    })
  }

  const close = (index: number) => {
    notifications.value.splice(index, 1)
  }

  const clear = () => {
    toast.removeGroup('headless')
    notifications.value = []
  }

  const hasNotifications = computed<boolean>(() => notifications.value.length > 0)

  return {
    show,
    clear,
    close,
    shouldBeShown,
    notifications,
    hasNotifications
  }
})

useNuiEvent<Notification>('newNotification', (data: Notification) => {
  const notifications = useNotifications()

  notifications.show(data)
})
