<script lang="ts">
  import { onMount } from 'svelte'
  import type { AppType, InstallAppResponse, RemoveAppResponse } from '$lib/types/app.types'
  import { appsStore } from '$lib/stores/appsStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import Dialog from '$lib/components/Dialog.svelte'
  import AppComponent from './appStore/AppComponent.svelte'
  import AppViewOverlayComponent from './appStore/AppViewOverlayComponent.svelte'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  let overlayShown = $state(false)
  let overlayApp = $state<AppType | undefined>()
  let filter = $state('')
  let installDialogVisible = $state(false)
  let pendingInstallApp = $state<AppType | undefined>()

  let filteredApps = $derived(
    filter
      ? appsStore.appStoreApplications.filter((app) =>
          app.name?.toLowerCase().includes(filter.toLowerCase())
        )
      : appsStore.appStoreApplications
  )

  function openView(app: AppType) {
    overlayApp = app
    overlayShown = true
  }

  function closeView() {
    overlayApp = undefined
    overlayShown = false
  }

  function installApp(app: AppType) {
    if (app.isInstalled) return

    if (app.isOnDesktopByDefault) {
      doInstall(app, true)
      return
    }

    pendingInstallApp = app
    installDialogVisible = true
  }

  function confirmInstall(addToDesktop: boolean) {
    const app = pendingInstallApp
    installDialogVisible = false
    pendingInstallApp = undefined
    if (!app) return
    doInstall(app, addToDesktop)
  }

  async function doInstall(app: AppType, addToDesktop: boolean) {
    app.isInstalling = true

    const data = await fetchApi<InstallAppResponse>(
      'installApp',
      {
        method: 'POST',
        body: JSON.stringify({ id: app.id })
      },
      { success: true, error: undefined }
    )

    const { success, error } = data as InstallAppResponse

    if (!success) {
      app.isInstalling = false
      notificationsStore.show({
        summary: localeStore.t('app_store_unable_to_install'),
        detail: error || localeStore.t('app_store_unable_to_install_helptext')
      })
      return
    }

    if (addToDesktop) {
      appsStore.addDesktopIcon(app.id)
    }
  }

  async function removeApp(app: AppType) {
    if (!app.isInstalled) return

    app.isInstalling = true

    const data = await fetchApi<RemoveAppResponse>(
      'uninstallApp',
      {
        method: 'POST',
        body: JSON.stringify({ id: app.id })
      },
      { success: true, error: undefined }
    )

    const { success, error } = data as RemoveAppResponse

    app.isInstalling = false

    if (!success) {
      notificationsStore.show({
        summary: localeStore.t('app_store_unable_to_remove'),
        detail: error || localeStore.t('app_store_unable_to_remove_helptext')
      })
      return
    }

    notificationsStore.show({
      summary: localeStore.t('app_store_uninstall_success'),
      detail: localeStore.t('app_store_uninstall_success_helptext')
    })

    appsStore.markAsUninstalled(app.id)
  }

  onMount(() => {
    appReady()
    changeWindowTitle(localeStore.t('app_store_title'))
  })
</script>

<Dialog
  visible={installDialogVisible}
  header={localeStore.t('app_store_install_dialog_title')}
  onclose={() => { installDialogVisible = false; pendingInstallApp = undefined }}
>
  <p class="text-sm text-[#8B8D9A]">{localeStore.t('app_store_install_dialog_description')}</p>
  <div class="mt-4 flex gap-2">
    <button
      type="button"
      class="rounded-lg bg-[#5BBD6B] px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-[#4DAD5D]"
      onclick={() => confirmInstall(true)}
    >
      {localeStore.t('app_store_install_dialog_yes')}
    </button>
    <button
      type="button"
      class="rounded-lg bg-[#2D2F3A] px-3 py-1.5 text-xs font-medium text-[#F0F0F5] transition-colors hover:bg-[#3a3c4a]"
      onclick={() => confirmInstall(false)}
    >
      {localeStore.t('app_store_install_dialog_no')}
    </button>
  </div>
</Dialog>

<div class="relative flex flex-1 select-none flex-col gap-5 bg-[#16171C] p-5">
  {#if overlayShown && overlayApp}
    <AppViewOverlayComponent
      app={overlayApp}
      onclose={closeView}
      oninstall={installApp}
      onremove={removeApp}
    />
  {/if}

  <!-- Header -->
  <div class="flex items-center justify-between">
    <h2 class="text-xl font-semibold text-[#F0F0F5]">{localeStore.t('app_store_title')}</h2>
    <div class="relative">
      <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-xs text-[#50525E]"></i>
      <input
        bind:value={filter}
        placeholder="Search"
        type="text"
        class="w-48 rounded-lg border border-[#2D2F3A] bg-[#1E2028] py-1.5 pl-8 pr-3 text-sm text-[#F0F0F5] outline-none transition-colors placeholder:text-[#50525E] focus:border-[#7C8AED]"
      />
    </div>
  </div>

  <!-- App grid -->
  {#if filteredApps.length > 0}
    <div
      class="lscrollbar grid flex-1 grid-cols-2 gap-3 overflow-y-auto overflow-x-hidden pb-1 pr-1"
      style="grid-auto-rows: min-content;"
    >
      {#each filteredApps as app (app.id)}
        <AppComponent
          {app}
          onopenview={() => openView(app)}
          oninstall={() => installApp(app)}
          onremove={() => removeApp(app)}
        />
      {/each}
    </div>
  {:else}
    <div class="flex flex-1 flex-col items-center justify-center gap-3">
      <div class="flex h-14 w-14 items-center justify-center rounded-full bg-[#2D2F3A]">
        <i class="fa-solid fa-box-open text-xl text-[#50525E]"></i>
      </div>
      <div class="text-center">
        <h3 class="text-sm font-semibold text-[#F0F0F5]">
          {localeStore.t('app_store_nothing_here')}
        </h3>
        <p class="mt-1 text-xs text-[#8B8D9A]">
          {localeStore.t('app_store_nothing_here_helptext')}
        </p>
      </div>
    </div>
  {/if}
</div>
