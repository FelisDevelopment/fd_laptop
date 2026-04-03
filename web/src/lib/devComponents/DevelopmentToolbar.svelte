<script lang="ts">
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { developmentStore } from '$lib/stores/developmentStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import type { ExternalApp } from '$lib/types/app.types'

  let dropdownOpen = $state(false)

  function debugData(data: any) {
    window.postMessage(data, '*')
  }

  let deviceCounter = 0
  let appCounter = 0

  const items = [
    {
      label: 'Toggle daylight',
      command: () => developmentStore.toggleDaylight()
    },
    {
      label: 'Push notification',
      command: () =>
        notificationsStore.show({
          summary: 'Push Notification',
          detail: 'Testing notif.'
        })
    },
    {
      label: 'Add WiFi w password',
      command: () =>
        debugData({
          action: 'addNetwork',
          data: {
            ssid: 'test_w_password',
            label: 'Test W Password',
            password: '1234'
          }
        })
    },
    {
      label: 'Add WiFi w/o password',
      command: () =>
        debugData({
          action: 'addNetwork',
          data: {
            ssid: 'test_wo_password',
            label: 'Test W/O Password'
          }
        })
    },
    {
      label: 'Remove WiFis',
      command: () => {
        debugData({
          action: 'removeNetwork',
          data: 'test_w_password'
        })
        debugData({
          action: 'removeNetwork',
          data: 'test_wo_password'
        })
      }
    },
    {
      label: 'Add device',
      command: () => {
        deviceCounter++
        laptopStore.installedDevices.push({
          slot: deviceCounter,
          metadata: {
            deviceId: `dev_${deviceCounter}`,
            deviceLabel: `Test Device ${deviceCounter}`
          }
        })
      }
    },
    {
      label: 'Remove devices',
      command: () => {
        laptopStore.installedDevices = []
        deviceCounter = 0
      }
    },
    {
      label: 'Toggle needs update',
      command: () => {
        laptopStore.needsUpdate = !laptopStore.needsUpdate
      }
    },
    {
      label: 'Add mocked app',
      command: () => {
        appCounter++
        const mockApp: ExternalApp = {
          id: `mock_app_${appCounter}`,
          name: `Mock App ${appCounter}`,
          icon: 'app_store.svg',
          isInternal: false,
          ui: 'https://example.com',
          appstore: {
            description: `A mocked external application #${appCounter} for testing the app store.`,
            author: 'Developer',
            images: [
              'https://picsum.photos/seed/app1/800/450',
              'https://picsum.photos/seed/app2/800/450',
              'https://picsum.photos/seed/app3/800/450',
              'https://picsum.photos/seed/app4/800/450',
              'https://picsum.photos/seed/app5/800/450',
              'https://picsum.photos/seed/app6/800/450'
            ]
          },
          windowActions: {
            isResizable: true,
            isMaximizable: true,
            isClosable: true,
            isMinimizable: true,
            isDraggable: true
          }
        }
        appsStore.addNewApp(mockApp)
      }
    },
    {
      label: 'Remove mocked apps',
      command: () => {
        for (let i = 1; i <= appCounter; i++) {
          appsStore.removeApp(`mock_app_${i}`)
        }
        appCounter = 0
      }
    }
  ]
</script>

<div class="fixed left-5 top-5 z-[9999] flex gap-5">
  <div class="relative inline-flex rounded-md shadow-sm">
    <button
      type="button"
      class="rounded-l-md bg-gray-700 px-3 py-1.5 text-sm text-white hover:bg-gray-600"
      onclick={() => laptopStore.isOpen = !laptopStore.isOpen}
    >
      Toggle open state
    </button>
    <button
      type="button"
      aria-label="Toggle menu"
      class="rounded-r-md border-l border-gray-600 bg-gray-700 px-2 py-1.5 text-sm text-white hover:bg-gray-600"
      onclick={() => dropdownOpen = !dropdownOpen}
    >
      <i class="fa-solid fa-chevron-down text-xs"></i>
    </button>
    {#if dropdownOpen}
      <div class="absolute left-0 top-full z-10 mt-1 w-48 rounded-md bg-gray-800 shadow-lg">
        {#each items as item}
          <button
            type="button"
            class="block w-full px-4 py-2 text-left text-sm text-gray-100 hover:bg-gray-700"
            onclick={() => { item.command(); dropdownOpen = false }}
          >
            {item.label}
          </button>
        {/each}
      </div>
    {/if}
  </div>
</div>
