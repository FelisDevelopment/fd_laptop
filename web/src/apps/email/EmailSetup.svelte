<script lang="ts">
  import { untrack } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { clickOutside } from '$lib/utils/clickOutside'
  import { fetchApi } from '$lib/utils/api'

  let { config, oncreated, onback }: {
    config: { domains: string[]; maxAccounts: number }
    oncreated: (account: { id: number; address: string }) => void
    onback?: () => void
  } = $props()

  let username = $state('')
  let selectedDomain = $state(untrack(() => config.domains[0]))
  let error = $state('')
  let creating = $state(false)
  let domainOpen = $state(false)

  function selectDomain(domain: string) {
    selectedDomain = domain
    domainOpen = false
  }

  async function handleCreate() {
    error = ''
    const trimmed = username.trim().toLowerCase()

    if (trimmed.length < 3 || trimmed.length > 24) {
      error = localeStore.t('email_setup_invalid_username')
      return
    }

    if (!/^[a-z0-9._\-]+$/.test(trimmed)) {
      error = localeStore.t('email_setup_invalid_username')
      return
    }

    creating = true

    const result = await fetchApi<{ id?: number; address?: string; error?: string }>(
      'emailCreate',
      { method: 'POST', body: JSON.stringify({ username: trimmed, domain: selectedDomain }) },
      { id: Date.now(), address: `${trimmed}@${selectedDomain}` }
    )

    creating = false

    if (!result || result.error) {
      if (result?.error === 'address_taken') {
        error = localeStore.t('email_setup_username_taken')
      } else if (result?.error === 'max_accounts') {
        error = localeStore.t('email_max_accounts')
      } else {
        error = localeStore.t('email_setup_invalid_username')
      }
      return
    }

    if (result.id && result.address) {
      oncreated({ id: result.id, address: result.address })
    }
  }
</script>

<div class="flex-1 flex flex-col items-center justify-center gap-2 p-8 select-none relative">
  {#if onback}
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button type="button" class="absolute top-3 left-3 flex items-center gap-[6px] bg-none border-none text-[#8B8D9A] text-xs font-medium font-inherit cursor-pointer py-[6px] px-[10px] rounded-lg transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730]" onclick={onback}>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
      <span>{localeStore.t('email_back')}</span>
    </button>
  {/if}

  <div class="text-[#7C8AED] mb-2">
    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
  </div>
  <h2 class="text-[#F0F0F5] text-lg font-bold m-0">{localeStore.t('email_setup_title')}</h2>
  <p class="text-[#6B6D7A] text-[13px] m-0 mb-4 text-center max-w-[300px]">{localeStore.t('email_setup_description')}</p>

  <div class="flex flex-col items-center gap-[10px] w-full max-w-[360px]">
    <div class="email-setup-domain-dropdown flex items-center w-full bg-[#252730] border border-[#2D2F3A] rounded-xl overflow-visible relative" use:clickOutside={{ callback: () => { domainOpen = false } }}>
      <input
        type="text"
        class="flex-1 min-w-0 bg-transparent border-none text-[#F0F0F5] text-[13px] py-[10px] px-3 outline-none font-inherit placeholder:text-[#50525E]"
        placeholder={localeStore.t('email_setup_username_placeholder')}
        bind:value={username}
        maxlength={24}
        onkeydown={(e) => { if (e.key === 'Enter') handleCreate() }}
      />
      <span class="text-[#50525E] text-[13px] shrink-0">@</span>
      <div class="relative shrink-0">
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="flex items-center gap-1 bg-none border-none text-[#C8C9CF] text-[13px] font-inherit py-[10px] pr-3 pl-[6px] cursor-pointer transition-colors duration-150 whitespace-nowrap hover:text-[#F0F0F5]" onclick={() => { domainOpen = !domainOpen }}>
          <span>{selectedDomain}</span>
          <svg class="text-[#50525E] transition-transform duration-150 shrink-0 {domainOpen ? 'rotate-180' : ''}" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>
        </button>
        {#if domainOpen}
          <div class="absolute top-[calc(100%+4px)] right-0 min-w-[150px] bg-[#252730] border border-[#2D2F3A] rounded-xl p-1 z-10 shadow-lg flex flex-col gap-px">
            {#each config.domains as domain}
              <!-- svelte-ignore a11y_consider_explicit_label -->
              <button
                type="button"
                class="w-full py-2 px-3 bg-none border-none rounded-lg text-xs font-inherit cursor-pointer text-left transition-colors duration-[120ms] hover:bg-[#2D2F3A] hover:text-[#F0F0F5] {selectedDomain === domain ? 'text-[#F0F0F5] bg-[rgba(91,123,237,0.12)]' : 'text-[#C8C9CF]'}"
                onclick={() => selectDomain(domain)}
              >{domain}</button>
            {/each}
          </div>
        {/if}
      </div>
    </div>

    {#if error}
      <p class="text-[#E55B5B] text-xs m-0">{error}</p>
    {/if}

    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button
      type="button"
      class="w-full py-[10px] bg-[#7C8AED] text-white border-none rounded-xl text-[13px] font-semibold font-inherit cursor-pointer transition-colors duration-150 hover:bg-[#6B79DC] disabled:opacity-50 disabled:cursor-not-allowed"
      onclick={handleCreate}
      disabled={creating || !username.trim()}
    >
      {creating ? '...' : localeStore.t('email_setup_create')}
    </button>
  </div>
</div>
