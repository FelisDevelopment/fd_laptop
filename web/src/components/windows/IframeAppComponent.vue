<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useConnection } from '../../stores/connection.store'
import { useNotifications } from '../../stores/notifications.store'
import { useSettings } from '../../stores/settings.store'
import { onKeyUp, useEventBus, useEventListener } from '@vueuse/core'
import { onBeforeUnmount, onMounted, useTemplateRef, type CSSProperties } from 'vue'
import type { AppMessage, ExternalApp } from '../../types/app.types'
import { parentResourceName } from '../../utils/parentResource.utils'
import { useLaptop } from '../../stores/laptop.store'
import { useNuiEvent } from '../../composables/useNuiEvent'
import { useApi } from '../../composables/useApi'

const props = defineProps<InternalAppWindowBinds<ExternalApp>>()

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

const getAppData = () => {
  if (!iframe.value) return

  postMessage({
    action: `${props.app.id}:appData`,
    data: JSON.stringify(props.app)
  })
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

const markAsReady = async () => {
  if (!iframe.value) return

  if (props.app.onUse || props.app.onUseServer) {
    await useApi<null>(
      'appOpened',
      {
        method: 'POST',
        body: JSON.stringify({ id: props.app.id })
      },
      undefined,
      null
    )
  }

  childComponentsLoaded()

  postMessage({
    action: 'onOpen',
    data: {}
  })

  props.appReady()
  iframeStyles()
}

const iframeEvents = () => {
  if (!iframe.value) return

  const childEvents: Record<string, (data?: any) => void> = {
    appReady: () => markAsReady(),
    changeWindowTitle: (newTitle: string) => props.changeWindowTitle(newTitle),
    getAppData: () => getAppData(),
    getSettings: () => getSettings(),
    getNetworkSettings: () => getNetworkSettings(),
    getDevices: () => getInstalledDevices(),
    sendNotification: (data: { summary: string; detail: string }) => sendNotification(data)
  }

  useEventListener(iframe.value.contentWindow!, 'message', (event: MessageEvent) => {
    if (typeof event.data === 'string') {
      if (!childEvents[event.data]) return

      return childEvents[event.data](event.data)
    }

    const { action, data } = event.data

    if (!childEvents[action]) return

    childEvents[action](data)
  })
}

const iframeBindings = () => {
  if (!iframe.value) return

  const body = iframe.value.contentWindow?.document.head
  if (!body) return

  if (props.app.overrides && Array.isArray(props.app.overrides)) {
    props.app.overrides.forEach((override) => {
      const script = document.createElement('script')
      script.setAttribute('src', override)
      body.prepend(script)
    })
  }

  const globalScript = document.createElement('script')
  globalScript?.setAttribute('src', `https://cfx-nui-${parentResourceName}/web/dist/global.js`)
  body?.prepend(globalScript)

  const globalDefinition = document.createElement('script')
  globalDefinition.appendChild(
    document.createTextNode(`
        globalThis.resourceName = '${props.app.resourceName}'
        globalThis.appId = '${props.app.id}'
    `)
  )
  body?.prepend(globalDefinition)
}

const awaitForContent = () => {
  if (!iframe.value) return

  try {
    iframe.value!.contentWindow?.postMessage(
      {
        action: 'showMenu'
      },
      '*'
    )

    const iframeDoc = iframe.value.contentDocument || iframe.value.contentWindow!.document

    const observer = new MutationObserver(async (mutations) => {
      let hasContent = false
      mutations.forEach((mutation) => {
        if (mutation.addedNodes.length > 0) {
          hasContent = true
        }
      })

      if (hasContent) {
        markAsReady()

        observer.disconnect()
      }
    })

    observer.observe(iframeDoc.body, {
      childList: true,
      subtree: true
    })
  } catch (e) {
    console.error('Error while loading external app:', e)
  }
}

const awaitForAlpineToLoad = () => {
  if (!iframe.value) return

  const checkAlpine = () => {
    //@ts-ignore
    if (iframe.value!.contentWindow?.Alpine) {
      markAsReady()
      return
    }

    setTimeout(checkAlpine, 100)
  }

  checkAlpine()
}

const iframeLoaded = () => {
  if (!iframe.value) return

  if (props.app.ui.includes('rahe-') || props.app.ui.includes('kub-')) {
    awaitForAlpineToLoad()
  } else {
    awaitForContent()
  }

  iframeEvents()
  iframeBindings()
}

const childComponentsLoaded = () => {
  if (props.app.ui.includes('rahe-')) {
    raheOverrides()
  }

  if (props.app.ui.includes('kub_')) {
    kubOverrides()
  }
}

const kubOverrides = (show: boolean = true) => {
  iframe.value!.contentWindow?.postMessage(
    {
      type: show ? 'showUI' : 'hideUI'
    },
    '*'
  )

  if (show) {
    const body = iframe.value!.contentWindow?.document.body!

    body.firstElementChild?.setAttribute(
      'style',
      'position:relative; margin: 0; left: 0; top: 0; width: 100%; height: 100%; max-height: auto; max-width: auto; transform: none;'
    )

    const head = iframe.value!.contentWindow?.document.head!
    const style = head.appendChild(document.createElement('style'))
    style.setAttribute('type', 'text/css')
    style.appendChild(
      document.createTextNode(
        '.border-image { border-image: unset !important; } .ipad{border: unset !important;} .ipad::after{display:none !important;}'
      )
    )
  }
}

const raheOverrides = (show: boolean = true) => {
  iframe.value!.contentWindow?.postMessage(
    {
      action: show ? 'showMenu' : 'hideMenu'
    },
    '*'
  )

  if (show) {
    const body = iframe.value!.contentWindow?.document.body!

    body.firstElementChild?.setAttribute(
      'style',
      'position:relative; margin: 0; left: 0; top: 0; width: 100%; height: 100%;'
    )

    body.getElementsByClassName('tablet-frame')[0]?.remove()
  }
}

onMounted(async () => {
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

  onKeyUp(
    'Escape',
    () => {
      if (!laptop.isOpen) return

      laptop.close(true)
    },
    {
      target: iframe.value!.contentWindow?.window
    }
  )
})

useNuiEvent<AppMessage>('sendAppMessage', (data: AppMessage) => {
  if (data.id !== props.app.id) return

  postMessage(data.message)
})

onBeforeUnmount(async () => {
  if (props.app.ui.includes('rahe-')) {
    raheOverrides(false)
  }

  if (props.app.ui.includes('kub-')) {
    kubOverrides(false)
  }

  postMessage({
    action: 'closeApp'
  })

  if (props.app.onClose || props.app.onCloseServer) {
    await useApi<null>(
      'appClosed',
      {
        method: 'POST',
        body: JSON.stringify({ id: props.app.id })
      },
      undefined,
      null
    )
  }
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
