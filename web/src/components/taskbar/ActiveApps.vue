<script setup lang="ts">
import { defineAsyncComponent } from 'vue'
import { useApplications } from '../../stores/apps.store'

const apps = useApplications()
const ActiveAppButton = defineAsyncComponent(() => import('./ActiveAppButton.vue'))

const toggleStates = (id: string) => {
  if (!apps.windows[id].state.isMinimized) {
    apps.toggleActiveState(id, false)
    apps.toggleMinimizeState(id, true)

    return
  }

  apps.toggleActiveState(id, true)
  apps.toggleMinimizeState(id, false)
}
</script>
<template>
  <div class="z-10 flex flex-1 gap-1 py-1">
    <ActiveAppButton
      v-for="window in apps.shownWindows"
      v-tooltip.top="window.app.name"
      :key="window.app.id"
      :state="window.state"
      :id="window.app.id"
      :icon="window.app.icon"
      :isActive="window.state.isActive && !window.state.isMinimized"
      @click="toggleStates(window.app.id)"
    />
  </div>
</template>
