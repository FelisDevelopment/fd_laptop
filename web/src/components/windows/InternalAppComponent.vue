<script setup lang="ts">
import type { InternalApp } from '../../types/app.types'
import type { InternalAppWindowBinds } from '../../types/window.types'

defineProps<InternalAppWindowBinds<InternalApp>>()
</script>
<template>
  <component
    :is="app.component"
    :appReady="appReady"
    :changeWindowTitle="changeWindowTitle"
    :metadata="metadata"
  ></component>
</template>
