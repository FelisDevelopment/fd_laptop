<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useNotifications } from '../../stores/notifications.store'
import { useConnection } from '../../stores/connection.store'
import { defineAsyncComponent, onMounted, ref } from 'vue'
import { useApi } from '../../composables/useApi'
import { useDialog } from 'primevue/usedialog'
import { useEventBus, watchDebounced } from '@vueuse/core'
import ToggleButton from 'primevue/togglebutton'
import ProgressSpinner from 'primevue/progressspinner'
import { useLocale } from '../../stores/locale.store'

interface ConnectionResponse {
  success: boolean
  error?: string
}

const WifiPasswordDialog = defineAsyncComponent(
  () => import('../../components/dialogs/WifiPassword.vue')
)

const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()
const locale = useLocale()
const connection = useConnection()
const notif = useNotifications()
const dialog = useDialog()
const bus = useEventBus('network')

const isConnecting = ref<boolean>(false)

const connect = async (ssid: string, password?: string) => {
  const { data } = await useApi<ConnectionResponse>(
    'connectTo',
    {
      method: 'POST',
      body: JSON.stringify({ ssid, password })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success, error } = data.value as ConnectionResponse

  bus.emit('updated')

  isConnecting.value = false

  if (!success) {
    return notif.show({
      summary: locale.t('settings_wifi_connection_error'),
      detail: error!
    })
  }

  connection.markAsConnected(ssid)

  notif.show({
    summary: locale.t('settings_wifi_connection_succ'),
    detail: `${locale.t('settings_wifi_connected_to')}${ssid}`
  })
}

const connectUsingPassword = (ssid: string) => {
  isConnecting.value = true

  dialog.open(WifiPasswordDialog, {
    props: {
      header: locale.t('settings_wifi_modal_title'),
      modal: true
    },
    onClose: (data) => {
      const { data: password } = data!
      isConnecting.value = false

      if (!password) return

      connect(ssid, password)
    }
  })
}

const initConnection = async (ssid: string) => {
  if (isConnecting.value) return
  if (connection.airplaneMode) return

  const network = connection.networks.find((network) => network.ssid === ssid)

  if (!network) return

  if (network.connected) {
    return disconnect()
  }

  if (network.password) {
    return connectUsingPassword(ssid)
  }

  isConnecting.value = true

  connect(ssid)
}

const disconnect = async () => {
  if (isConnecting.value) return

  isConnecting.value = true

  const { data } = await useApi<ConnectionResponse>(
    'disconnect',
    {
      method: 'POST'
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success, error } = data.value as ConnectionResponse

  bus.emit('updated')

  isConnecting.value = false

  if (!success) {
    notif.show({
      summary: locale.t('settings_wifi_connection_error'),
      detail: error!
    })
  }

  connection.markAsDisconnected()
  connection.connectedToVpn = false

  notif.show({
    summary: locale.t('settings_wifi_disconnect_succ'),
    detail: locale.t('settings_wifi_disconnect_succ_detail')
  })
}

const toggleVpn = async (status: boolean) => {
  const { data } = await useApi<ConnectionResponse>(
    'toggleVpn',
    {
      method: 'POST',
      body: JSON.stringify({
        status: status
      })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success } = data.value as ConnectionResponse

  bus.emit('updated')

  if (!success) {
    connection.connectedToVpn = false

    return
  }

  notif.show({
    summary: 'VPN connection',
    detail: status ? locale.t('settings_wifi_vpn_enabled') : locale.t('settings_wifi_vpn_disabled')
  })
}

watchDebounced(
  () => connection.connectedToVpn,
  (value) => {
    toggleVpn(value)
  },
  { debounce: 100 }
)

watchDebounced(
  () => connection.airplaneMode,
  (value) => {
    if (value) {
      disconnect()

      return notif.show({
        summary: locale.t('settings_wifi_airplane_mode_enabled'),
        detail: locale.t('settings_wifi_airplane_mode_enabled_detail')
      })
    }

    notif.show({
      summary: locale.t('settings_wifi_airplane_mode_disabled'),
      detail: locale.t('settings_wifi_airplane_mode_disabled_detail')
    })
  },
  { debounce: 100 }
)

onMounted(() => {
  props.changeWindowTitle(locale.t('settings_wifi_title'))
})
</script>
<template>
  <div class="flex flex-1 flex-col items-center justify-start gap-5 overflow-auto">
    <div
      class="flex w-full items-center justify-between rounded-lg bg-gray-300 px-2 py-2 dark:bg-gray-800"
    >
      <div class="flex w-2/3 flex-col">
        <span class="text-sm font-semibold text-color">
          {{ locale.t('settings_wifi_airplane_mode') }}
        </span>
        <span class="break-words text-xs text-muted-color">
          {{ locale.t('settings_wifi_airplane_mode_description') }}
        </span>
      </div>
      <ToggleButton
        class="w-24"
        v-model="connection.airplaneMode"
        :onLabel="locale.t('settings_wifi_airplane_mode_on')"
        :offLabel="locale.t('settings_wifi_airplane_mode_off')"
        size="small"
      />
    </div>

    <div
      v-if="connection.isConnected"
      class="flex w-full items-center justify-between rounded-lg bg-gray-300 px-2 py-2 dark:bg-gray-800"
    >
      <div class="flex w-2/3 flex-col">
        <span class="text-sm font-semibold text-color">
          {{ locale.t('settings_wifi_vpn_mode') }}
        </span>
        <span class="break-words text-xs text-muted-color">
          {{ locale.t('settings_wifi_vpn_mode_description') }}
        </span>
      </div>
      <ToggleButton
        class="w-24"
        @click.prevent=""
        v-model="connection.connectedToVpn"
        :onLabel="locale.t('settings_wifi_vpn_mode_on')"
        :offLabel="locale.t('settings_wifi_vpn_mode_off')"
        size="small"
      />
    </div>

    <div class="flex w-full flex-1 flex-col gap-2" v-if="!connection.airplaneMode">
      <div class="flex w-full items-center justify-between text-sm font-semibold text-muted-color">
        <span>{{ locale.t('settings_wifi_networks') }}</span>
        <ProgressSpinner style="width: 1em; height: 1em; margin: 0" v-if="isConnecting" />
      </div>
      <div class="w-full flex-1 overflow-auto rounded-lg bg-gray-300 dark:bg-gray-800">
        <div
          class="py-4 text-center text-xs text-muted-color"
          v-if="connection.networks.length < 1"
        >
          {{ locale.t('settings_wifi_no_networks') }}
        </div>
        <ul v-else class="divide-y divide-gray-200/40 dark:divide-gray-700/40">
          <li
            @click.prevent="initConnection(network.ssid)"
            v-for="network in connection.networks"
            class="flex items-center justify-between px-5 py-4 hover:cursor-pointer hover:bg-emphasis hover:text-color-emphasis"
            :class="{
              'text-color-emphasis': network.connected,
              'text-muted-color': !network.connected
            }"
          >
            <div class="flex items-center gap-5 text-sm">
              <i class="pi pi-wifi"></i>
              <span>{{ network.label }}</span>
            </div>
            <div class="flex items-center gap-5 text-sm">
              <i class="pi pi-lock" v-if="network.password && !network.connected"></i>
              <span v-if="network.connected" class="text-xs text-muted-color">
                {{ locale.t('settings_wifi_connected_title') }}
              </span>
              <i class="pi pi-chevron-right text-xs" v-else></i>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
