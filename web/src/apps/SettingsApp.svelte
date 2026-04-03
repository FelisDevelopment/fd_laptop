<script lang="ts">
  import { onMount } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import Avatar from '$lib/components/Avatar.svelte'
  import WifiTab from './settings/WifiTab.svelte'
  import NotificationsTab from './settings/NotificationsTab.svelte'
  import BackgroundTab from './settings/BackgroundTab.svelte'
  import ProfileTab from './settings/ProfileTab.svelte'
  import DevicesTab from './settings/DevicesTab.svelte'
  import SecurityTab from './settings/SecurityTab.svelte'
  import InformationTab from './settings/InformationTab.svelte'

  type AvailableTabs =
    | 'wifi'
    | 'notifications'
    | 'background'
    | 'information'
    | 'profile'
    | 'devices'
    | 'security'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  let currentTab = $state<AvailableTabs>('wifi')

  let tabs = $derived<Record<AvailableTabs, { icon: string; label: string; iconColor: string }>>({
    wifi: {
      icon: 'fa-solid fa-wifi',
      label: localeStore.t('settings_wifi_tab_label'),
      iconColor: 'text-blue-400'
    },
    notifications: {
      icon: 'fa-solid fa-bell',
      label: localeStore.t('settings_notifications_tab_label'),
      iconColor: 'text-red-400'
    },
    background: {
      icon: 'fa-solid fa-image',
      label: localeStore.t('settings_background_tab_label'),
      iconColor: 'text-teal-400'
    },
    profile: {
      icon: 'fa-solid fa-user',
      label: localeStore.t('settings_profile_tab_label'),
      iconColor: 'text-[#8B8D9A]'
    },
    devices: {
      icon: 'fa-solid fa-server',
      label: localeStore.t('settings_devices_tab_label'),
      iconColor: 'text-[#8B8D9A]'
    },
    security: {
      icon: 'fa-solid fa-shield-halved',
      label: localeStore.t('settings_security_tab_label'),
      iconColor: 'text-[#7C8AED]'
    },
    information: {
      icon: 'fa-solid fa-circle-info',
      label: localeStore.t('settings_system_information_tab_label'),
      iconColor: 'text-[#8B8D9A]'
    }
  })

  let navTabs = $derived(Object.entries(tabs).filter(([key]) => key !== 'profile') as [AvailableTabs, (typeof tabs)[AvailableTabs]][])

  function switchTab(tab: AvailableTabs) {
    if (tab === currentTab) return
    currentTab = tab
  }

  onMount(() => {
    appReady()

    if (metadata?.tab) {
      switchTab(metadata.tab)
    }
  })
</script>

<div class="flex flex-1 select-none overflow-hidden">
  <div class="flex w-[200px] shrink-0 flex-col bg-[#1E2028]">
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="flex cursor-pointer items-center gap-3 px-4 py-4 hover:bg-[#252730]"
      onclick={() => switchTab('profile')}
    >
      <Avatar
        image={settingsStore.profilePicture}
        icon={settingsStore.profilePicture ? undefined : 'fa-solid fa-user'}
        size="normal"
      />
      <div class="flex flex-col overflow-hidden">
        <span class="truncate text-[13px] font-semibold text-[#F0F0F5]">{settingsStore.username || 'User'}</span>
        {#if settingsStore.job}
          <span class="truncate text-[11px] text-[#8B8D9A]">{settingsStore.job}</span>
        {/if}
      </div>
    </div>

    <div class="mx-3 border-t border-[#2D2F3A]"></div>

    <nav class="flex flex-1 flex-col gap-0.5 p-2">
      {#each navTabs as [key, tab]}
        <button
          type="button"
          class="flex cursor-pointer items-center gap-2.5 rounded-lg px-3 py-1.5 text-[13px] transition-colors duration-150 {currentTab === key ? 'bg-[#2D2F3A] text-[#F0F0F5]' : 'text-[#8B8D9A] hover:bg-[#252730]'}"
          onclick={() => switchTab(key)}
        >
          <i class="w-4 text-center {tab.icon} {currentTab === key ? tab.iconColor : 'text-[#50525E]'}"></i>
          {tab.label}
        </button>
      {/each}
    </nav>
  </div>

  <div class="flex flex-1 flex-col overflow-hidden bg-[#16171C] p-5">
    {#if currentTab === 'wifi'}
      <WifiTab {changeWindowTitle} />
    {:else if currentTab === 'notifications'}
      <NotificationsTab {changeWindowTitle} />
    {:else if currentTab === 'background'}
      <BackgroundTab {changeWindowTitle} />
    {:else if currentTab === 'profile'}
      <ProfileTab {changeWindowTitle} />
    {:else if currentTab === 'devices'}
      <DevicesTab {changeWindowTitle} />
    {:else if currentTab === 'security'}
      <SecurityTab {changeWindowTitle} />
    {:else if currentTab === 'information'}
      <InformationTab {changeWindowTitle} />
    {/if}
  </div>
</div>
