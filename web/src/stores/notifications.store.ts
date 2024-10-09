import { defineStore } from 'pinia'
import { useToast } from '../services/usetoast'
import { computed, ref } from 'vue'
import type { Notification } from '../types/notification.types'
import { useSettings } from './settings.store'

export const useNotifications = defineStore('notifications', () => {
  const settings = useSettings()
  const toast = useToast()
  const notifications = ref<Notification[]>([])

  const show = (data: Omit<Notification, 'time'>) => {
    notifications.value.push({
      summary: data.summary,
      detail: data.detail,
      time: new Date()
    })

    if (settings.doNotDisturb) return

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
    notifications,
    hasNotifications
  }
})
