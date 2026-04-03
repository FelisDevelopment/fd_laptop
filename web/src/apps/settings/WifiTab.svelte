<script lang="ts">
  import { onMount } from 'svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { connectionStore } from '$lib/stores/connectionStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { networkBus } from '$lib/utils/eventBus'
  import { debounce } from '$lib/utils/debounce'
  import ToggleSwitch from '$lib/components/ToggleSwitch.svelte'
  import ProgressSpinner from '$lib/components/ProgressSpinner.svelte'
  import Dialog from '$lib/components/Dialog.svelte'
  import WifiPassword from '$lib/views/dialogs/WifiPassword.svelte'

  interface ConnectionResponse {
    success: boolean
    error?: string
  }

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  let isConnecting = $state(false)
  let showPasswordDialog = $state(false)
  let pendingPasswordSsid = $state('')

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

  async function initConnection(ssid: string) {
    if (isConnecting) return
    if (connectionStore.airplaneMode) return

    const network = connectionStore.networks.find((network) => network.ssid === ssid)
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
      notificationsStore.show({
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

  async function toggleVpn(status: boolean) {
    const data = await fetchApi<ConnectionResponse>(
      'toggleVpn',
      {
        method: 'POST',
        body: JSON.stringify({ status })
      },
      { success: true, error: undefined }
    )

    const { success } = data as ConnectionResponse

    if (!success) {
      connectionStore.connectedToVpn = false
      networkBus.emit('updated')
      return
    }

    networkBus.emit('updated')

    notificationsStore.show({
      summary: localeStore.t('settings_wifi_vpn_conn_title'),
      detail: status ? localeStore.t('settings_wifi_vpn_enabled') : localeStore.t('settings_wifi_vpn_disabled')
    })
  }

  const debouncedToggleVpn = debounce((val: boolean) => toggleVpn(val), 100)
  const debouncedAirplaneMode = debounce((val: boolean) => {
    networkBus.emit('updated')

    if (val) {
      disconnect()
      notificationsStore.show({
        summary: localeStore.t('settings_wifi_airplane_mode_enabled'),
        detail: localeStore.t('settings_wifi_airplane_mode_enabled_detail')
      })
      return
    }

    notificationsStore.show({
      summary: localeStore.t('settings_wifi_airplane_mode_disabled'),
      detail: localeStore.t('settings_wifi_airplane_mode_disabled_detail')
    })
  }, 100)

  let prevVpn = connectionStore.connectedToVpn
  $effect(() => {
    const val = connectionStore.connectedToVpn
    if (val !== prevVpn) {
      prevVpn = val
      debouncedToggleVpn(val)
    }
  })

  let prevAirplane = connectionStore.airplaneMode
  $effect(() => {
    const val = connectionStore.airplaneMode
    if (val !== prevAirplane) {
      prevAirplane = val
      debouncedAirplaneMode(val)
    }
  })

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_wifi_title'))
  })
</script>

<Dialog
  header={localeStore.t('settings_wifi_modal_title')}
  visible={showPasswordDialog}
  onclose={handlePasswordCancel}
>
  <WifiPassword onsubmit={handlePasswordSubmit} oncancel={handlePasswordCancel} />
</Dialog>

<div class="flex flex-1 flex-col gap-4 overflow-y-auto overflow-x-hidden">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_wifi_tab_label')}
  </h2>

  <div class="divide-y divide-[#2D2F3A] rounded-xl bg-[#1E2028]">
    <div class="flex items-center justify-between px-4 py-3">
      <div class="flex items-center gap-3">
        <div class="flex h-7 w-7 items-center justify-center rounded-lg bg-orange-500">
          <i class="fa-solid fa-plane text-xs text-white"></i>
        </div>
        <div class="flex flex-col">
          <span class="text-sm font-medium text-[#F0F0F5]">
            {localeStore.t('settings_wifi_airplane_mode')}
          </span>
          <span class="text-[11px] text-[#8B8D9A]">
            {localeStore.t('settings_wifi_airplane_mode_description')}
          </span>
        </div>
      </div>
      <ToggleSwitch
        bind:checked={connectionStore.airplaneMode}
      />
    </div>

    {#if connectionStore.isConnected}
      <div class="flex items-center justify-between px-4 py-3">
        <div class="flex items-center gap-3">
          <div class="flex h-7 w-7 items-center justify-center rounded-lg bg-blue-500">
            <i class="fa-solid fa-shield-halved text-xs text-white"></i>
          </div>
          <div class="flex flex-col">
            <span class="text-sm font-medium text-[#F0F0F5]">
              {localeStore.t('settings_wifi_vpn_mode')}
            </span>
            <span class="text-[11px] text-[#8B8D9A]">
              {localeStore.t('settings_wifi_vpn_mode_description')}
            </span>
          </div>
        </div>
        <ToggleSwitch
          bind:checked={connectionStore.connectedToVpn}
        />
      </div>
    {/if}
  </div>

  {#if !connectionStore.airplaneMode}
    <div class="flex flex-1 flex-col gap-2">
      <div class="flex items-center justify-between px-1">
        <span class="text-xs font-medium uppercase tracking-wide text-[#8B8D9A]">
          {localeStore.t('settings_wifi_networks')}
        </span>
        {#if isConnecting}
          <ProgressSpinner size="1em" />
        {/if}
      </div>
      <div class="flex-1 overflow-y-auto overflow-x-hidden rounded-xl bg-[#1E2028]">
        {#if connectionStore.networks.length < 1}
          <div class="flex flex-col items-center justify-center gap-2 py-8 text-[#50525E]">
            <i class="fa-solid fa-wifi text-2xl opacity-30"></i>
            <span class="text-xs">{localeStore.t('settings_wifi_no_networks')}</span>
          </div>
        {:else}
          <ul class="divide-y divide-[#2D2F3A]">
            {#each connectionStore.networks as network}
              <!-- svelte-ignore a11y_click_events_have_key_events -->
              <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
              <li
                onclick={() => initConnection(network.ssid)}
                class="flex items-center justify-between px-4 py-3 hover:cursor-pointer hover:bg-[#252730]"
              >
                <div class="flex items-center gap-3 text-sm">
                  <i class="fa-solid fa-wifi {network.connected ? 'text-[#5BBD6B]' : 'text-[#50525E]'}"></i>
                  <span class="text-[#F0F0F5]">{network.label}</span>
                </div>
                <div class="flex items-center gap-3 text-sm">
                  {#if network.password && !network.connected}
                    <i class="fa-solid fa-lock text-xs text-[#50525E]"></i>
                  {/if}
                  {#if network.connected}
                    <span class="rounded-full bg-[#5BBD6B]/20 px-2 py-0.5 text-[11px] font-medium text-[#5BBD6B]">
                      {localeStore.t('settings_wifi_connected_title')}
                    </span>
                  {:else}
                    <i class="fa-solid fa-chevron-right text-xs text-[#50525E]"></i>
                  {/if}
                </div>
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    </div>
  {/if}
</div>
