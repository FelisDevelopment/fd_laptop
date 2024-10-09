<script setup lang="ts">
import { useDevelopment } from '../stores/development.store'
import { useNotifications } from '../stores/notifications.store'
import Button from 'primevue/button'

const dev = useDevelopment()
const noticiation = useNotifications()
</script>
<template>
  <div class="fixed left-5 top-5 flex gap-5">
    <Button label="Toogle daylight" @click.prevent="dev.toggleDaylight()" size="small" />
    <Button
      label="Push Notifications"
      @click.prevent="
        noticiation.show({
          summary: 'Push Notification',
          detail:
            'Lorem ipsum dolor, sit amet consectetur adipisicing elit. Voluptatibus deleniti illo maxime recusandae quod facere nemo. Facilis quo nemo culpa!'
        })
      "
      size="small"
    />
  </div>
</template>
