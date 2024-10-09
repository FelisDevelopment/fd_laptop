<script setup lang="ts">
import { useNotifications } from '../../stores/notifications.store'
import { onClickOutside, useTimeAgo } from '@vueuse/core'
import { ref } from 'vue'
//@ts-ignore
import Toast from '../../services/toast/Toast.vue'
import { useApplications } from '../../stores/apps.store'
import Button from 'primevue/button'
import { useLocale } from '../../stores/locale.store'

defineProps({
  isOpen: {
    type: Boolean,
    default: false
  }
})

const locale = useLocale()
const apps = useApplications()
const notif = useNotifications()

const overlay = ref<HTMLDivElement>()
const emit = defineEmits(['close'])

onClickOutside(overlay, () => {
  emit('close')
})

const openSettings = () => {
  emit('close')
  apps.open('settings', { tab: 'notifications' })
}
</script>
<template>
  <Teleport to="#laptop" defer>
    <Toast position="bottom-right" group="headless" to="#laptop" v-show="!isOpen">
      <template #container="{ message, closeCallback }">
        <div
          class="block space-y-1 rounded bg-white/50 p-3 text-sm backdrop-blur-xl hover:bg-white/25 active:bg-white/50 dark:bg-black/30 dark:hover:bg-black/50 dark:active:bg-black/30"
        >
          <div class="flex items-center justify-between">
            <h3 class="font-medium">{{ message.summary }}</h3>
            <Button
              icon="pi pi-times"
              size="small"
              rounded
              outlined
              aria-label="Close"
              @click.prevent="closeCallback"
            />
          </div>
          <p class="leading-5 text-gray-700 dark:text-gray-400">
            {{ message.detail }}
          </p>
        </div>
      </template>
    </Toast>
  </Teleport>
  <Teleport to="#laptop" defer>
    <Transition
      name="custom-notifications"
      enter-active-class="transition ease-linear duration-100"
      enter-from-class="opacity-0 translate-x-full"
      enter-to-class="opacity-100 translate-x-0"
      leave-active-class="transition ease-linear duration-100"
      leave-from-class="opacity-100 translate-x-0"
      leave-to-class="opacity-0 translate-x-60"
    >
      <div
        v-show="isOpen"
        ref="overlay"
        id="notifications-area"
        class="absolute bottom-0 right-0 top-0 z-[999] flex w-96 transform flex-col bg-gray-100/60 backdrop-blur-xl dark:bg-gray-800/60"
      >
        <div class="flex flex-1 flex-col overflow-hidden pr-2">
          <div class="flex items-center justify-between py-4 pl-4">
            <span class="text-lg font-semibold">{{ locale.t('notifications_overlay_title') }}</span>
            <Button
              icon="pi pi-times"
              aria-label="Close"
              size="small"
              link
              @click.prevent="emit('close')"
            />
          </div>
          <div
            class="flex-1 space-y-2 overflow-y-auto px-4 scrollbar-thin scrollbar-track-rounded-[100px] scrollbar-thumb-rounded-[100px] scrollbar-corner-rounded-[100px] dark:scrollbar-track-gray-500/80 dark:scrollbar-thumb-gray-400/80"
          >
            <div
              class="block space-y-1 rounded bg-white/50 p-3 text-sm hover:bg-white/25 active:bg-white/50 dark:bg-black/30 dark:hover:bg-black/50 dark:active:bg-black/30"
              v-for="(notification, index) in notif.notifications"
            >
              <div class="flex items-center justify-between">
                <h3 class="font-medium">{{ notification.summary }}</h3>
                <Button
                  icon="pi pi-times"
                  size="small"
                  rounded
                  outlined
                  aria-label="Close"
                  @click.prevent="notif.close(index)"
                />
              </div>
              <p class="leading-5 text-gray-700 dark:text-gray-400">
                {{ notification.detail }}
              </p>
              <p class="text-gray-600 dark:text-gray-500">{{ useTimeAgo(notification.time) }}</p>
            </div>
          </div>
          <div class="flex justify-between">
            <Button
              :label="locale.t('notifications_overlay_settings_button')"
              @click.prevent="openSettings()"
              link
              size="small"
            />

            <Button
              :label="locale.t('notifications_overlay_clear_button')"
              @click.prevent="notif.clear()"
              link
              size="small"
            />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
