<script setup lang="ts">
import { defineAsyncComponent } from 'vue'

import Divider from 'primevue/divider'

const StartMenu = defineAsyncComponent(() => import('./taskbar/StartMenu.vue'))
const ActiveApps = defineAsyncComponent(() => import('./taskbar/ActiveApps.vue'))
const TaskbarBlock = defineAsyncComponent(() => import('./taskbar/TaskbarBlock.vue'))

defineProps<{
  parent: HTMLDivElement
}>()
</script>
<template>
  <div
    id="start-menu"
    class="fixed inset-x-0 bottom-3 z-50 mx-5 flex h-14 flex-none select-none px-2 before:absolute before:inset-0 before:z-0 before:rounded-lg before:bg-gray-100/50 before:backdrop-blur-sm before:dark:bg-gray-800/50"
  >
    <StartMenu :parent="parent" />
    <Divider layout="vertical" />
    <ActiveApps />
    <Divider layout="vertical" />
    <TaskbarBlock />
  </div>
</template>
