<script setup lang="ts">
import { useLocale } from '../../stores/locale.store'
import { inject, ref } from 'vue'

const dialogRef = inject('dialogRef')
const locale = useLocale()
const password = ref<string>('')

const connect = () => {
  if (!password.value) return

  //@ts-ignore
  dialogRef.value.close(password.value)
}
const cancel = () => {
  //@ts-ignore
  dialogRef.value.close(null)
}
</script>
<template>
  <div class="flex flex-col items-center rounded bg-surface-0 p-4 dark:bg-gray-900">
    <div class="flex flex-col gap-2">
      <InputText id="password" v-model="password" aria-describedby="password-help" />
      <small id="password-help">{{ locale.t('wifi_password_field_helptext') }}</small>
    </div>
    <div class="mt-6 flex items-center gap-2">
      <Button :label="locale.t('wifi_connect_button')" @click="connect" class="w-32"></Button>
      <Button
        :label="locale.t('wifi_connect_cancel_button')"
        outlined
        @click="cancel"
        class="w-32"
      ></Button>
    </div>
  </div>
</template>
