<script lang="ts">
  import { localeStore } from '$lib/stores/localeStore.svelte'

  interface Email {
    id: number
    owner_address: string
    from_address: string
    to_address: string
    subject: string
    body: string
    folder: string
    is_read: boolean
    created_at: string
  }

  type Folder = 'inbox' | 'sent' | 'trash'

  type ReadFilter = 'all' | 'read' | 'unread'

  let { emails, loading, hasMore, onselect, onloadmore, folder, searchQuery, onsearch, readFilter, onreadfilter, ondeleteall }: {
    emails: Email[]
    loading: boolean
    hasMore: boolean
    onselect: (email: Email) => void
    onloadmore: () => void
    folder: Folder
    searchQuery: string
    onsearch: (query: string) => void
    readFilter: ReadFilter
    onreadfilter: (filter: ReadFilter) => void
    ondeleteall: () => void
  } = $props()

  let deleteAllConfirm = $state(false)

  $effect(() => {
    void folder
    deleteAllConfirm = false
  })

  function stripHtml(html: string): string {
    if (!html) return ''
    return html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
  }

  function formatDate(dateStr: string): string {
    try {
      const d = new Date(dateStr)
      const now = new Date()
      const isToday = d.toDateString() === now.toDateString()
      if (isToday) {
        return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      }
      return d.toLocaleDateString([], { month: 'short', day: 'numeric' })
    } catch {
      return dateStr
    }
  }

  function getPreview(body: string): string {
    const text = stripHtml(body)
    if (!text) return ''
    return text.length > 80 ? text.substring(0, 80) + '...' : text
  }

  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  function handleSearchInput(e: Event) {
    const value = (e.target as HTMLInputElement).value
    if (debounceTimer) clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
      onsearch(value)
    }, 350)
  }

  function handleSearchClear() {
    if (debounceTimer) clearTimeout(debounceTimer)
    onsearch('')
  }
</script>

<div class="flex-1 flex flex-col min-h-0">
  <div class="flex items-center py-2 px-3 border-b border-[#1E2028] shrink-0 relative">
    <svg class="absolute left-5 text-[#50525E] pointer-events-none" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
    <input
      type="text"
      class="flex-1 bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-xs py-[7px] px-[30px] outline-none font-inherit transition-colors duration-150 box-border min-w-0 focus:border-[#7C8AED] placeholder:text-[#50525E]"
      placeholder={localeStore.t('email_search_placeholder')}
      value={searchQuery}
      oninput={handleSearchInput}
    />
    {#if searchQuery}
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="absolute right-[18px] w-5 h-5 flex items-center justify-center bg-none border-none text-[#50525E] cursor-pointer rounded p-0 transition-colors duration-150 hover:text-[#8B8D9A]" onclick={handleSearchClear}>
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
      </button>
    {/if}
  </div>
  <div class="flex items-center gap-[6px] py-[6px] px-3 border-b border-[#1E2028] shrink-0">
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button
      type="button"
      class="py-1 px-3 border rounded-2xl text-[11px] font-medium font-inherit cursor-pointer transition-colors duration-150 whitespace-nowrap {readFilter === 'all' ? 'text-[#F0F0F5] bg-[#7C8AED] border-[#7C8AED] hover:bg-[#6B79DC] hover:border-[#6B79DC]' : 'bg-none border-[#2D2F3A] text-[#6B6D7A] hover:text-[#8B8D9A] hover:border-[#3A3D4A]'}"
      onclick={() => onreadfilter('all')}
    >{localeStore.t('email_filter_all')}</button>
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button
      type="button"
      class="py-1 px-3 border rounded-2xl text-[11px] font-medium font-inherit cursor-pointer transition-colors duration-150 whitespace-nowrap {readFilter === 'unread' ? 'text-[#F0F0F5] bg-[#7C8AED] border-[#7C8AED] hover:bg-[#6B79DC] hover:border-[#6B79DC]' : 'bg-none border-[#2D2F3A] text-[#6B6D7A] hover:text-[#8B8D9A] hover:border-[#3A3D4A]'}"
      onclick={() => onreadfilter('unread')}
    >{localeStore.t('email_filter_unread')}</button>
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button
      type="button"
      class="py-1 px-3 border rounded-2xl text-[11px] font-medium font-inherit cursor-pointer transition-colors duration-150 whitespace-nowrap {readFilter === 'read' ? 'text-[#F0F0F5] bg-[#7C8AED] border-[#7C8AED] hover:bg-[#6B79DC] hover:border-[#6B79DC]' : 'bg-none border-[#2D2F3A] text-[#6B6D7A] hover:text-[#8B8D9A] hover:border-[#3A3D4A]'}"
      onclick={() => onreadfilter('read')}
    >{localeStore.t('email_filter_read')}</button>
    {#if emails.length > 0}
      <div class="ml-auto flex items-center gap-[6px]">
        {#if deleteAllConfirm}
          <button
            type="button"
            class="py-1 px-3 border rounded-2xl text-[11px] font-medium font-inherit cursor-pointer transition-colors duration-150 whitespace-nowrap text-[#F0F0F5] bg-[#E55B5B] border-[#E55B5B] hover:bg-[#D14A4A] hover:border-[#D14A4A]"
            onclick={() => { deleteAllConfirm = false; ondeleteall() }}
          >{localeStore.t('email_delete_all_confirm')}</button>
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button
            type="button"
            class="w-6 h-6 flex items-center justify-center bg-none border border-[#2D2F3A] rounded-full text-[#6B6D7A] cursor-pointer transition-colors duration-150 hover:text-[#8B8D9A] hover:border-[#3A3D4A]"
            onclick={() => deleteAllConfirm = false}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </button>
        {:else}
          <button
            type="button"
            class="flex items-center gap-[5px] py-1 px-3 border rounded-2xl text-[11px] font-medium font-inherit cursor-pointer transition-colors duration-150 whitespace-nowrap bg-none border-[#2D2F3A] text-[#6B6D7A] hover:text-[#E55B5B] hover:border-[#E55B5B]/50"
            onclick={() => deleteAllConfirm = true}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
            {localeStore.t('email_delete_all')}
          </button>
        {/if}
      </div>
    {/if}
  </div>
  {#if loading}
    <div class="h-[2px] w-full bg-[#1E2028] overflow-hidden shrink-0"><div class="email-loading-bar-fill h-full w-[40%] bg-[#7C8AED] rounded-[1px]"></div></div>
  {/if}
  <div class="flex-1 overflow-y-auto flex flex-col min-h-0 lscrollbar">
  {#if loading && emails.length === 0}
    <div class="flex-1 flex items-center justify-center"><div class="w-5 h-5 border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
  {:else if emails.length === 0}
    <div class="flex-1 flex flex-col items-center justify-center gap-[10px] text-[#50525E] text-[13px] font-medium">
      <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" opacity="0.3"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
      <span>{localeStore.t('email_no_emails')}</span>
    </div>
  {:else}
    {#each emails as email (email.id)}
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button
        type="button"
        class="flex items-start w-full py-[10px] px-[14px] border-none border-b border-b-[#1E2028] text-left cursor-pointer transition-colors duration-[120ms] font-inherit {!email.is_read ? 'bg-[rgba(91,123,237,0.04)] hover:bg-[rgba(91,123,237,0.08)]' : 'bg-none hover:bg-[#1A1B21]'}"
        onclick={() => onselect(email)}
      >
        <div class="w-[18px] shrink-0 flex items-center justify-center pt-[6px]">
          {#if !email.is_read}
            <span class="w-[7px] h-[7px] bg-[#7C8AED] rounded-full"></span>
          {/if}
        </div>
        <div class="flex-1 min-w-0 flex flex-col gap-[2px]">
          <div class="flex items-center justify-between gap-2">
            <span class="text-[#F0F0F5] text-xs font-semibold truncate flex-1 min-w-0">
              {email.folder === 'sent' ? email.to_address : email.from_address}
            </span>
            <span class="text-[#50525E] text-[10px] font-medium shrink-0">{formatDate(email.created_at)}</span>
          </div>
          <span class="text-[#C8C9CF] text-xs font-medium truncate">{email.subject || localeStore.t('email_no_subject')}</span>
          <span class="text-[#50525E] text-[11px] truncate">{getPreview(email.body)}</span>
        </div>
      </button>
    {/each}

    {#if hasMore}
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="py-[10px] bg-none border-none text-[#7C8AED] text-xs font-semibold font-inherit cursor-pointer transition-colors duration-150 text-center hover:text-[#9BA5F2] disabled:opacity-50 disabled:cursor-not-allowed" onclick={onloadmore} disabled={loading}>
        {loading ? '...' : localeStore.t('email_load_more')}
      </button>
    {/if}
  {/if}
  </div>
</div>

<style>
  .email-loading-bar-fill {
    animation: email-loading-slide 0.8s ease-in-out infinite;
  }
  @keyframes email-loading-slide {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(350%); }
  }
</style>
