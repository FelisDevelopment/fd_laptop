<script setup lang="ts">
import type { WindowStates } from '../../types/window.types'
import { useApplications } from '../../stores/apps.store'
import { iconUrl } from '../../utils/url.utils'

defineProps<{
  id: string
  icon: string
  isActive: boolean
  state: WindowStates
}>()

const apps = useApplications()
</script>
<template>
  <button
    class="hover-scale top-shadow pointer-events-auto relative flex h-12 w-14 items-center justify-center rounded px-2 hover:bg-gray-100/50 dark:hover:bg-gray-800/50"
    :class="{ 'bg-gray-100/50 dark:bg-gray-800/50': isActive && !state.isMinimized }"
  >
    <img :src="iconUrl(icon)" class="h-8 w-8" />
    <div
      class="absolute bottom-px left-1/2 h-1 w-[30%] -translate-x-1/2 transform rounded-lg bg-blue-500/80"
      v-if="isActive && !state.isMinimized"
    ></div>
  </button>
</template>
