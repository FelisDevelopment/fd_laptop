<script setup lang="ts">
import { useLaptop } from '../stores/laptop.store'
import { useDevelopment } from '../stores/development.store'
import { useNotifications } from '../stores/notifications.store'
import SplitButton from 'primevue/splitbutton'

const dev = useDevelopment()
const noticiation = useNotifications()
const laptop = useLaptop()

const debugData = (data: any) => {
  window.postMessage(data, '*')
}

const items = [
  {
    label: 'Toggle daylight',
    command: () => dev.toggleDaylight()
  },
  {
    label: 'Push notification',
    command: () =>
      noticiation.show({
        summary: 'Push Notification',
        detail:
          'Lorem ipsum dolor, sit amet consectetur adipisicing elit. Voluptatibus deleniti illo maxime recusandae quod facere nemo. Facilis quo nemo culpa!'
      })
  },
  {
    label: 'Add WiFi w password',
    command: () =>
      debugData({
        action: 'addNetwork',
        data: {
          ssid: 'test_w_password',
          label: 'Test W Password',
          password: '1234'
        }
      })
  },
  {
    label: 'Add WiFi w/o password',
    command: () =>
      debugData({
        action: 'addNetwork',
        data: {
          ssid: 'test_wo_password',
          label: 'Test W/O Password'
        }
      })
  },
  {
    label: 'Remove WiFis',
    command: () => {
      debugData({
        action: 'removeNetwork',
        data: 'test_w_password'
      })

      debugData({
        action: 'removeNetwork',
        data: 'test_wo_password'
      })
    }
  }
]
</script>
<template>
  <div class="fixed left-5 top-5 flex gap-5">
    <SplitButton
      label="Toggle open state"
      dropdownIcon="pi pi-chevron-down"
      @click.prevent="laptop.isOpen = !laptop.isOpen"
      :model="items"
      size="small"
    />
  </div>
</template>
