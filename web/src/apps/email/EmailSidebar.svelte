<script lang="ts">
  import { localeStore } from '$lib/stores/localeStore.svelte'

  interface Account {
    id: number
    address: string
  }

  type Folder = 'inbox' | 'sent' | 'trash'

  let { accounts, activeAccount, config, onaccountchange, oncompose, folder, onfolderchange, unreadCount, onnewaccount }: {
    accounts: Account[]
    activeAccount: Account | null
    config: { domains: string[]; maxAccounts: number }
    onaccountchange: (account: Account) => void
    oncompose: () => void
    folder: Folder
    onfolderchange: (folder: Folder) => void
    unreadCount: number
    onnewaccount: () => void
  } = $props()

  const folders: { id: Folder; icon: string }[] = [
    { id: 'inbox', icon: 'inbox' },
    { id: 'sent', icon: 'sent' },
    { id: 'trash', icon: 'trash' },
  ]

  let accountDropdownOpen = $state(false)

  function selectAccount(acc: Account) {
    accountDropdownOpen = false
    if (acc.address !== activeAccount?.address) {
      onaccountchange(acc)
    }
  }

  function handleClickOutside(e: MouseEvent) {
    const target = e.target as HTMLElement
    if (!target.closest('.email-sb-dropdown')) {
      accountDropdownOpen = false
    }
  }
</script>

<!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
<div class="w-[200px] min-w-[200px] flex flex-col bg-[#1A1B21] border-r border-[#2D2F3A] py-3 px-2 gap-1 select-none" onclick={handleClickOutside}>
  <div class="pt-1 px-1 pb-2">
    {#if accounts.length > 1}
      <div class="email-sb-dropdown relative">
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="flex items-center gap-1 w-full py-[7px] px-[10px] bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#C8C9CF] text-[11px] font-inherit cursor-pointer transition-colors duration-150 text-left hover:border-[#3A3D4A] hover:text-[#F0F0F5]" onclick={() => { accountDropdownOpen = !accountDropdownOpen }}>
          <span class="flex-1 min-w-0 truncate">{activeAccount?.address || ''}</span>
          <svg class="text-[#50525E] transition-transform duration-150 shrink-0 {accountDropdownOpen ? 'rotate-180' : ''}" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>
        </button>
        {#if accountDropdownOpen}
          <div class="absolute top-[calc(100%+4px)] left-0 right-0 bg-[#252730] border border-[#2D2F3A] rounded-xl p-1 z-10 shadow-lg flex flex-col gap-px">
            {#each accounts as acc}
              <!-- svelte-ignore a11y_consider_explicit_label -->
              <button
                type="button"
                class="w-full py-[7px] px-[10px] bg-none border-none rounded-lg text-[11px] font-inherit cursor-pointer text-left transition-colors duration-[120ms] truncate hover:bg-[#2D2F3A] hover:text-[#F0F0F5] {activeAccount?.address === acc.address ? 'text-[#F0F0F5] bg-[rgba(91,123,237,0.12)]' : 'text-[#C8C9CF]'}"
                onclick={() => selectAccount(acc)}
              >{acc.address}</button>
            {/each}
          </div>
        {/if}
      </div>
    {:else if activeAccount}
      <span class="text-[#8B8D9A] text-[11px] font-medium truncate block px-1">{activeAccount.address}</span>
    {/if}
  </div>

  <!-- svelte-ignore a11y_consider_explicit_label -->
  <button type="button" class="flex items-center gap-2 w-full py-[9px] px-3 bg-[#7C8AED] text-white border-none rounded-xl text-xs font-semibold font-inherit cursor-pointer transition-colors duration-150 mb-1 hover:bg-[#6B79DC]" onclick={oncompose}>
    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
    <span>{localeStore.t('email_compose')}</span>
  </button>

  <div class="flex flex-col gap-px">
    {#each folders as f}
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button
        type="button"
        class="flex items-center gap-[10px] w-full py-2 px-3 border-none rounded-lg text-xs font-medium font-inherit cursor-pointer transition-colors duration-150 text-left {folder === f.id ? 'bg-[#252730] text-[#F0F0F5]' : 'bg-none text-[#8B8D9A] hover:bg-[#252730] hover:text-[#C8C9CF]'}"
        onclick={() => onfolderchange(f.id)}
      >
        {#if f.id === 'inbox'}
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>
        {:else if f.id === 'sent'}
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/></svg>
        {:else}
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
        {/if}
        <span>{localeStore.t('email_' + f.id)}</span>
        {#if f.id === 'inbox' && unreadCount > 0}
          <span class="ml-auto bg-[#7C8AED] text-white text-[10px] font-bold py-px px-[6px] rounded-xl min-w-[18px] text-center">{unreadCount > 99 ? '99+' : unreadCount}</span>
        {/if}
      </button>
    {/each}
  </div>

  <div class="flex-1"></div>

  {#if accounts.length < config.maxAccounts}
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button type="button" class="flex items-center gap-2 w-full py-2 px-3 bg-none border border-[#2D2F3A] rounded-lg text-[#6B6D7A] text-[11px] font-medium font-inherit cursor-pointer transition-colors duration-150 hover:border-[#3A3D4A] hover:text-[#8B8D9A]" onclick={onnewaccount}>
      <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
      <span>{localeStore.t('email_new_account')}</span>
    </button>
  {/if}
</div>
