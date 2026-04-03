<script lang="ts">
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { connectionStore } from '$lib/stores/connectionStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { networkBus } from '$lib/utils/eventBus'
  import { clickOutside } from '$lib/utils/clickOutside'
  import Dialog from '$lib/components/Dialog.svelte'
  import WifiPassword from '$lib/views/dialogs/WifiPassword.svelte'

  interface ConnectionResponse {
    success: boolean
    error?: string
  }

  let isOpen = $state(false)
  let isConnecting = $state(false)
  let showPasswordDialog = $state(false)
  let pendingPasswordSsid = $state('')

  function openWifiSettings() {
    isOpen = false
    appsStore.open('settings', { tab: 'wifi' })
  }

  async function connect(ssid: string, password?: string) {
    const data = await fetchApi<ConnectionResponse>(
      'connectTo',
      {
        method: 'POST',
        body: JSON.stringify({ ssid, password })
      },
      { success: true, error: undefined }
    )

    const { success, error } = data as ConnectionResponse

    isConnecting = false

    if (!success) {
      networkBus.emit('updated')
      return notificationsStore.show({
        summary: localeStore.t('settings_wifi_connection_error'),
        detail: error!
      })
    }

    connectionStore.markAsConnected(ssid)

    networkBus.emit('updated')
    notificationsStore.show({
      summary: localeStore.t('settings_wifi_connection_succ'),
      detail: `${localeStore.t('settings_wifi_connected_to')}${ssid}`
    })
  }

  async function disconnect() {
    if (isConnecting) return

    isConnecting = true

    const data = await fetchApi<ConnectionResponse>(
      'disconnect',
      { method: 'POST' },
      { success: true, error: undefined }
    )

    const { success, error } = data as ConnectionResponse

    isConnecting = false

    if (!success) {
      networkBus.emit('updated')
      return notificationsStore.show({
        summary: localeStore.t('settings_wifi_connection_error'),
        detail: error!
      })
    }

    connectionStore.markAsDisconnected()
    connectionStore.connectedToVpn = false

    networkBus.emit('updated')
    notificationsStore.show({
      summary: localeStore.t('settings_wifi_disconnect_succ'),
      detail: localeStore.t('settings_wifi_disconnect_succ_detail')
    })
  }

  function connectUsingPassword(ssid: string) {
    isConnecting = true
    pendingPasswordSsid = ssid
    showPasswordDialog = true
  }

  function handlePasswordSubmit(password: string) {
    showPasswordDialog = false
    connect(pendingPasswordSsid, password)
  }

  function handlePasswordCancel() {
    showPasswordDialog = false
    isConnecting = false
  }

  function initConnection(ssid: string) {
    if (isConnecting) return
    if (connectionStore.airplaneMode) return

    const network = connectionStore.networks.find((n) => n.ssid === ssid)
    if (!network) return

    if (network.connected) {
      return disconnect()
    }

    if (network.password) {
      return connectUsingPassword(ssid)
    }

    isConnecting = true
    connect(ssid)
  }
</script>

<Dialog
  header={localeStore.t('settings_wifi_modal_title')}
  visible={showPasswordDialog}
  onclose={handlePasswordCancel}
>
  <WifiPassword onsubmit={handlePasswordSubmit} oncancel={handlePasswordCancel} />
</Dialog>

{#if isOpen}
  <div
    class="absolute bottom-16 right-0 z-50 w-72 rounded-xl bg-[#1E2028] shadow-xl"
    use:clickOutside={{ callback: () => isOpen = false, ignore: ['#wifi-button'] }}
  >
    <div class="flex items-center justify-between px-4 pt-4 pb-2">
      <span class="text-sm font-semibold text-gray-100">
        {localeStore.t('settings_wifi_tab_label')}
      </span>
      <button
        type="button"
        aria-label="Close"
        class="flex h-6 w-6 items-center justify-center rounded-lg text-gray-400 transition-colors hover:bg-gray-700/80"
        onclick={() => isOpen = false}
      >
        <i class="fa-solid fa-xmark text-xs"></i>
      </button>
    </div>

    <div class="mx-3 mb-2 flex items-center justify-between rounded-lg px-2 py-2 transition-colors hover:bg-white/5">
      <div class="flex items-center gap-2.5">
        <div class="flex h-7 w-7 items-center justify-center rounded-lg bg-orange-500">
          <i class="fa-solid fa-plane text-xs text-white"></i>
        </div>
        <span class="text-[13px] text-gray-100">
          {localeStore.t('settings_wifi_airplane_mode')}
        </span>
      </div>
      <!-- svelte-ignore a11y_click_events_have_key_events -->
      <!-- svelte-ignore a11y_no_static_element_interactions -->
      <div
        class="relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full transition-colors duration-150 {connectionStore.airplaneMode ? 'bg-blue-600' : 'bg-gray-600'}"
        onclick={() => connectionStore.airplaneMode = !connectionStore.airplaneMode}
      >
        <span
          class="inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform duration-150 {connectionStore.airplaneMode ? 'translate-x-[1.1rem]' : 'translate-x-0.5'}"
        ></span>
      </div>
    </div>

    {#if !connectionStore.airplaneMode}
      <div class="border-t border-gray-700/50">
        {#if connectionStore.networks.length > 0}
          <div class="max-h-40 overflow-y-auto px-2 py-1.5">
            {#each connectionStore.networks as network}
              <button
                type="button"
                class="flex w-full items-center justify-between rounded-lg px-2.5 py-2 transition-colors hover:bg-white/10 {network.connected ? '' : 'text-gray-400'}"
                disabled={isConnecting}
                onclick={() => initConnection(network.ssid)}
              >
                <div class="flex items-center gap-2.5">
                  {#if isConnecting && ((network.connected) || (pendingPasswordSsid === network.ssid))}
                    <i class="fa-solid fa-spinner fa-spin text-xs text-[#7C8AED]"></i>
                  {:else}
                    <i class="fa-solid fa-wifi text-xs {network.connected ? 'text-[#7C8AED]' : ''}"></i>
                  {/if}
                  <span class="text-[13px] {network.connected ? 'font-medium text-gray-100' : ''}">{network.label}</span>
                </div>
                {#if network.connected}
                  <span class="rounded-full bg-green-900/30 px-1.5 py-0.5 text-[10px] font-medium text-green-400">
                    {localeStore.t('settings_wifi_connected_title')}
                  </span>
                {:else if network.password}
                  <i class="fa-solid fa-lock text-[10px]"></i>
                {/if}
              </button>
            {/each}
          </div>
        {:else}
          <div class="flex flex-col items-center gap-1.5 py-5 text-gray-400">
            <i class="fa-solid fa-wifi text-lg opacity-30"></i>
            <span class="text-[11px]">{localeStore.t('settings_wifi_no_networks')}</span>
          </div>
        {/if}
      </div>
    {:else}
      <div class="border-t border-gray-700/50 py-5 text-center">
        <span class="text-[11px] text-gray-400">{localeStore.t('settings_wifi_airplane_mode')}</span>
      </div>
    {/if}

    <div class="border-t border-gray-700/50 px-3 py-2.5">
      <button
        type="button"
        class="w-full rounded-lg py-1.5 text-[13px] font-medium text-[#7C8AED] transition-colors hover:bg-[#7C8AED]/10"
        onclick={openWifiSettings}
      >
        {localeStore.t('notifications_overlay_settings_button')}
      </button>
    </div>
  </div>
{/if}

<button
  id="wifi-button"
  onclick={() => isOpen = !isOpen}
  type="button"
  aria-label="WiFi"
  class="relative flex h-8 w-8 items-center justify-center rounded-lg transition-colors hover:bg-white/10 focus:outline-none active:scale-95 active:bg-white/15"
>
  {#if !connectionStore.isConnected}
    <i
      class="fa-solid fa-xmark absolute right-0.5 top-1"
      style="font-size: 0.4rem"
    ></i>
  {/if}
  <i class="fa-solid fa-wifi"></i>
</button>
