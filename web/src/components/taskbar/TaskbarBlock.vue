<script setup lang="ts">
import { defineAsyncComponent } from 'vue'

const TaskbarApps = defineAsyncComponent(() => import('./TaskbarApps.vue'))
const Clock = defineAsyncComponent(() => import('./Clock.vue'))
const Notifications = defineAsyncComponent(() => import('./Notifications.vue'))
</script>
<template>
  <div class="z-10 flex items-center">
    <TaskbarApps />
    <Clock />
    <Notifications />
  </div>
</template>
