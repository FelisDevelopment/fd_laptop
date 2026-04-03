<script lang="ts">
  import { onMount, onDestroy, untrack } from 'svelte'
  import { connectionStore } from '$lib/stores/connectionStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { parentResourceName } from '$lib/utils/parentResource.utils'
  import { fetchApi } from '$lib/utils/api'
  import { settingsBus, networkBus } from '$lib/utils/eventBus'
  import { onNuiEvent } from '$lib/utils/nuiEvent'
  import type { AppMessage, ExternalApp } from '$lib/types/app.types'

  import { appsStore } from '$lib/stores/appsStore.svelte'

  let { app, metadata, appReady, changeWindowTitle }: {
    app: ExternalApp
    metadata?: Record<string, any>
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  let appWindow = $derived(appsStore.windows[app.id])

  let iframeEl = $state<HTMLIFrameElement | null>(null)
  let ready = false
  const cleanups: (() => void)[] = []

  function postMessage(data: any) {
    iframeEl?.contentWindow?.postMessage(data, '*')
  }

  function iframeStyles() {
    if (!iframeEl) return
    const styles = 'visibility: visible; width: 100%; height: 100%; padding: 0; margin: 0;'
    iframeEl.contentDocument?.documentElement.setAttribute('style', styles)
    iframeEl.contentDocument?.body.setAttribute('style', styles)
  }

  async function markAsReady() {
    if (!iframeEl || ready) return
    ready = true

    if (app.onUseServer) {
      await fetchApi<null>('appOpened', { method: 'POST', body: JSON.stringify({ id: app.id }) }, null)
    }

    postMessage({ action: 'onOpen', data: {} })
    appReady()
    iframeStyles()
  }

  function detectAndAwaitFramework() {
    if (!iframeEl) return

    if (app.isAlpine) {
      awaitForAlpine()
    } else if (app.isReactOrVue) {
      awaitForContent()
    } else {
      setTimeout(markAsReady, 1000)
    }
  }

  function awaitForAlpine() {
    if (!iframeEl) return

    let retries = 0
    const MAX_RETRIES = 50

    const check = () => {
      if ((iframeEl!.contentWindow as any)?.Alpine) {
        return markAsReady()
      }
      if (++retries < MAX_RETRIES) {
        setTimeout(check, 100)
      } else {
        console.warn(`Alpine.js not detected after ${MAX_RETRIES} retries for app: ${app.id}`)
        markAsReady()
      }
    }

    check()
  }

  function awaitForContent() {
    if (!iframeEl) return

    try {
      const iframeDoc = iframeEl.contentDocument || iframeEl.contentWindow!.document

      const observer = new MutationObserver((mutations) => {
        for (const mutation of mutations) {
          if (mutation.addedNodes.length > 0) {
            markAsReady()
            observer.disconnect()
            return
          }
        }
      })

      observer.observe(iframeDoc.body, { childList: true, subtree: true })
    } catch (e) {
      console.error('Error while loading external app:', e)
    }
  }

  function setupIframeEvents() {
    if (!iframeEl) return

    const childEvents: Record<string, (data?: any) => void> = {
      appReady: () => markAsReady(),
      changeWindowTitle: (newTitle: string) => changeWindowTitle(newTitle),
      getAppData: () => postMessage({ action: `${app.id}:appData`, data: JSON.stringify(app) }),
      getSettings: () => postMessage({ action: `${app.id}:settings`, data: settingsStore.forApps }),
      getNetworkSettings: () => postMessage({ action: `${app.id}:network`, data: connectionStore.forApps }),
      getDevices: () => postMessage({ action: `${app.id}:devices`, data: JSON.stringify(laptopStore.installedDevices) }),
      sendNotification: (data: { summary: string; detail: string }) => notificationsStore.show(data)
    }

    const handler = (event: MessageEvent) => {
      if (typeof event.data === 'string') {
        childEvents[event.data]?.(event.data)
        return
      }
      const { action, data } = event.data
      childEvents[action]?.(data)
    }

    iframeEl.contentWindow?.addEventListener('message', handler)
    cleanups.push(() => {
      try { iframeEl?.contentWindow?.removeEventListener('message', handler) } catch {}
    })
  }

  function injectScripts() {
    if (!iframeEl) return

    const head = iframeEl.contentWindow?.document.head
    if (!head) return

    const scripts: string[] = []

    if (app.overrides && Array.isArray(app.overrides)) {
      scripts.push(...app.overrides)
    }

    scripts.push(`https://cfx-nui-${parentResourceName}/web/dist/global.js`)

    for (const src of scripts) {
      const script = document.createElement('script')
      script.setAttribute('src', src)
      head.prepend(script)
    }

    const globalDefinition = document.createElement('script')
    globalDefinition.appendChild(
      document.createTextNode(`
        globalThis.resourceName = '${app.resourceName}'
        globalThis.appId = '${app.id}'
      `)
    )
    head.prepend(globalDefinition)
  }

  function attachKeyupHandler() {
    if (!iframeEl) return

    const keyupHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && laptopStore.isOpen) {
        laptopStore.close(true)
      }
    }

    try {
      iframeEl.contentWindow?.addEventListener('keyup', keyupHandler)
      cleanups.push(() => {
        try { iframeEl?.contentWindow?.removeEventListener('keyup', keyupHandler) } catch {}
      })
    } catch {}
  }

  function iframeLoaded() {
    if (!iframeEl) return

    injectScripts()
    setupIframeEvents()
    attachKeyupHandler()
    detectAndAwaitFramework()
  }

  $effect(() => {
    const hidden = appWindow?.isHidden
    if (hidden === undefined) return

    untrack(() => {
      if (hidden) {
        if (app.onCloseServer) {
          fetchApi<null>('appClosed', { method: 'POST', body: JSON.stringify({ id: app.id }) }, null)
        }
        postMessage({ action: 'closeApp' })
      } else if (ready) {
        if (app.onUseServer) {
          fetchApi<null>('appOpened', { method: 'POST', body: JSON.stringify({ id: app.id }) }, null)
        }
        postMessage({ action: 'onOpen', data: {} })
      }
    })
  })

  onMount(() => {
    const unsubSettings = settingsBus.on((event) => {
      if (event !== 'updated') return
      postMessage({ action: 'changedSettings', data: settingsStore.forApps })
    })
    cleanups.push(unsubSettings)

    const unsubNetwork = networkBus.on((event) => {
      if (event !== 'updated') return
      postMessage({ action: 'networkChanged', data: connectionStore.forApps })
    })
    cleanups.push(unsubNetwork)

    const unsubNui = onNuiEvent<AppMessage>('sendAppMessage', (data) => {
      if (data.id !== app.id) return
      postMessage(data.message)
    })
    cleanups.push(unsubNui)
  })

  onDestroy(async () => {
    for (const cleanup of cleanups) cleanup()

    postMessage({ action: 'closeApp' })

    if (app.onCloseServer) {
      await fetchApi<null>('appClosed', { method: 'POST', body: JSON.stringify({ id: app.id }) }, null)
    }
  })
</script>

<iframe
  bind:this={iframeEl}
  src={app.ui}
  title={app.id}
  onload={iframeLoaded}
  name={app.id}
  class="flex flex-1 overflow-hidden"
></iframe>
