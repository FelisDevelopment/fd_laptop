<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useConnection } from '../../stores/connection.store'
import { useNotifications } from '../../stores/notifications.store'
import { useSettings } from '../../stores/settings.store'
import { useEventBus, useEventListener } from '@vueuse/core'
import { onMounted, useTemplateRef, type CSSProperties } from 'vue'
import type { AppMessage, ExternalApp } from '../../types/app.types'
import { parentResourceName } from '../../utils/parentResource.utils'
import { useLaptop } from '../../stores/laptop.store'
import { useNuiEvent } from '../../composables/useNuiEvent'

const props = defineProps<InternalAppWindowBinds>()

const laptop = useLaptop()
const settings = useSettings()
const notyf = useNotifications()
const connection = useConnection()
const settingsBus = useEventBus('settings')
const networkBus = useEventBus('network')

const iframe = useTemplateRef<HTMLIFrameElement>('iframe')

const postMessage = (data: any) => {
  if (!iframe.value) return

  iframe.value.contentWindow?.postMessage(data, '*')
}

const getSettings = () => {
  if (!iframe.value) return

  postMessage({
    action: `${props.app.id}:settings`,
    data: settings.forApps
  })
}

const getNetworkSettings = () => {
  if (!iframe.value) return

  postMessage({
    action: `${props.app.id}:network`,
    data: connection.forApps
  })
}

const getInstalledDevices = () => {
  if (!iframe.value) return

  postMessage({
    action: `${props.app.id}:devices`,
    data: JSON.stringify(laptop.installedDevices)
  })
}

const sendNotification = (data: { summary: string; detail: string }) => {
  if (!iframe.value) return

  notyf.show(data)
}

const iframeStyles = () => {
  if (!iframe.value) return

  const styles: CSSProperties = {
    visibility: 'visible',
    width: `100%`,
    height: `100%`,
    padding: 0,
    margin: 0
  }

  const concentrated = Object.entries(styles)
    .map(([key, value]) => `${key}: ${value};`)
    .join(' ')

  iframe.value.contentDocument?.documentElement.setAttribute('style', concentrated)
  iframe.value.contentDocument?.body.setAttribute('style', concentrated)
}

const markAsReady = () => {
  if (!iframe.value) return

  props.appReady()
  iframeStyles()
}

const iframeEvents = () => {
  if (!iframe.value) return

  const childEvents: Record<string, (data?: any) => void> = {
    appReady: () => markAsReady(),
    changeWindowTitle: (newTitle: string) => props.changeWindowTitle(newTitle),
    getSettings: () => getSettings(),
    getNetworkSettings: () => getNetworkSettings(),
    getDevices: () => getInstalledDevices(),
    sendNotification: (data: { summary: string; detail: string }) => sendNotification(data)
  }

  useEventListener(iframe.value.contentWindow!, 'message', (event: MessageEvent) => {
    const { action, data } = event.data

    if (!childEvents[action]) return

    childEvents[action](data)
  })
}

const iframeBindings = () => {
  if (!iframe.value) return

  const body = iframe.value.contentWindow?.document.body
  if (!body) return

  const globalDefinition = body?.appendChild(document.createElement('script'))
  globalDefinition.appendChild(
    document.createTextNode(`
        globalThis.resourceName = '${props.app.resourceName}'
        globalThis.appId = '${props.app.id}'
    `)
  )

  const globalScript = body?.appendChild(document.createElement('script'))
  globalScript?.setAttribute('src', `https://cfx-nui-${parentResourceName}/web/dist/global.js`)
}

const iframeLoaded = () => {
  if (!iframe.value) return

  iframeEvents()
  iframeBindings()
}

onMounted(() => {
  settingsBus.on((event) => {
    if (event !== 'updated') return

    iframe.value!.contentWindow?.postMessage(
      {
        action: `changedSettings`,
        data: settings.forApps
      },
      '*'
    )
  })

  networkBus.on((event) => {
    if (event !== 'updated') return

    iframe.value!.contentWindow?.postMessage(
      {
        action: `networkChanged`,
        data: connection.forApps
      },
      '*'
    )
  })
})

useNuiEvent<AppMessage>('sendAppMessage', (data: AppMessage) => {
  if (data.id !== props.app.id) return

  postMessage(data.message)
})
</script>
<template>
  <iframe
    ref="iframe"
    :src="(app as ExternalApp).ui"
    :frame-id="app.id"
    :onload="iframeLoaded"
    :name="app.id"
  ></iframe>
</template>
