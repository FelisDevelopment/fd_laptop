<script setup lang="ts">
import { useNotifications } from '../../stores/notifications.store'
import { useSettings } from '../../stores/settings.store'
import { defineAsyncComponent, ref } from 'vue'

const NotificationsOverlay = defineAsyncComponent(
  () => import('../overlays/NotificationsOverlay.vue')
)

const settings = useSettings()
const notifications = useNotifications()
const isOpen = ref<boolean>(false)
</script>
<template>
  <NotificationsOverlay :isOpen="isOpen" @close="isOpen = false" />
  <button
    @click.prevent="isOpen = !isOpen"
    type="button"
    class="relative flex h-8 w-8 items-center justify-center rounded hover:bg-white/50 focus:outline-none active:scale-90 active:bg-white dark:hover:bg-black/25 dark:active:bg-black/50"
  >
    <span
      v-if="notifications.hasNotifications"
      class="absolute right-1 top-1 block h-1.5 w-1.5 rounded-full bg-red-500"
    >
    </span>
    <i
      class="pi"
      :class="{ 'pi-bell': !settings.doNotDisturb, 'pi-bell-slash': settings.doNotDisturb }"
    ></i>
  </button>
</template>
