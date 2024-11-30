<script setup lang="ts">
import { useApplications } from '../../stores/apps.store'
import { useConnection } from '../../stores/connection.store'
import Button from 'primevue/button'

const apps = useApplications()
const connection = useConnection()
</script>
<template>
  <Button asChild>
    <div
      @click.prevent="apps.open('settings', { tab: 'wifi' })"
      class="relative flex h-8 w-8 items-center justify-center rounded hover:cursor-pointer hover:bg-white/50 focus:outline-none active:scale-90 active:bg-white dark:hover:bg-black/25 dark:active:bg-black/50"
    >
      <i
        v-if="!connection.isConnected"
        class="pi pi-times absolute right-0.5 top-1"
        style="font-size: 0.4rem"
      ></i>
      <button class="flex items-center justify-center">
        <i class="pi pi-wifi"></i>
      </button>
    </div>
  </Button>
</template>
