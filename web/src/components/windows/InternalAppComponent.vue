<script setup lang="ts">
import type { InternalApp } from '../../types/app.types'
import type { InternalAppWindowBinds } from '../../types/window.types'

defineProps<InternalAppWindowBinds>()
</script>
<template>
  <component
    :is="(app as InternalApp).component"
    :appReady="appReady"
    :changeWindowTitle="changeWindowTitle"
    :metadata="metadata"
  ></component>
</template>
