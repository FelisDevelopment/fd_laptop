<script setup lang="ts">
import { defineAsyncComponent, onMounted } from 'vue'
import { useDevelopment } from './stores/development.store'
import { useLaptop } from './stores/laptop.store'
import { useNotifications } from './stores/notifications.store'

const Laptop = defineAsyncComponent(() => import('./components/Laptop.vue'))
const DevelopmentToolbar = defineAsyncComponent(
  () => import('./devComponents/DevelopmentToolbar.vue')
)

const dev = useDevelopment()
const laptop = useLaptop()
const notif = useNotifications()

onMounted(() => {
  if (dev.isDevEnv) {
    dev.applyDevelopmentStyles()
  }

  laptop.init()
})
</script>

<template>
  <Laptop v-show="laptop.isOpen || notif.shouldBeShown" />
  <DevelopmentToolbar v-if="dev.isDevEnv" />
</template>
