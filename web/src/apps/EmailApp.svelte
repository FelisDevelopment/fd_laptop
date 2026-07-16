<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { onNuiEvent } from '$lib/utils/nuiEvent'
  import EmailSetup from './email/EmailSetup.svelte'
  import EmailSidebar from './email/EmailSidebar.svelte'
  import EmailList from './email/EmailList.svelte'
  import EmailDetail from './email/EmailDetail.svelte'
  import EmailCompose from './email/EmailCompose.svelte'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  interface Account {
    id: number
    address: string
  }

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

  interface EmailConfig {
    domains: string[]
    maxAccounts: number
  }

  type Folder = 'inbox' | 'sent' | 'trash'

  const MOCK_CONFIG: EmailConfig = { domains: ['mail.com', 'eyefind.info', 'beemail.com'], maxAccounts: 3 }
  const MOCK_ACCOUNTS: Account[] = [
    { id: 1, address: 'player@mail.com' }
  ]
  const MOCK_EMAILS: Email[] = [
    { id: 1, owner_address: 'player@mail.com', from_address: 'boss@eyefind.info', to_address: 'player@mail.com', subject: 'Meeting Tomorrow', body: '<p>Hey, just a reminder about our <strong>meeting tomorrow</strong> at 3 PM.</p><p>Please bring the project files.</p>', folder: 'inbox', is_read: false, created_at: new Date(Date.now() - 1000 * 60 * 30).toISOString() },
    { id: 2, owner_address: 'player@mail.com', from_address: 'shop@beemail.com', to_address: 'player@mail.com', subject: 'Your Order Has Shipped', body: '<p>Your order <strong>#4521</strong> has been shipped!</p><ul><li>Tracking number: LS928371</li><li>Estimated delivery: 2-3 days</li></ul>', folder: 'inbox', is_read: true, created_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString() },
    { id: 3, owner_address: 'player@mail.com', from_address: 'noreply@eyefind.info', to_address: 'player@mail.com', subject: 'Welcome to Eyefind', body: '<p>Welcome to <strong>Eyefind</strong>! Your account has been created successfully.</p>', folder: 'inbox', is_read: true, created_at: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString() },
    { id: 4, owner_address: 'player@mail.com', from_address: 'player@mail.com', to_address: 'boss@eyefind.info', subject: 'Re: Meeting Tomorrow', body: '<p>Sure, I will be there with all the files. See you!</p>', folder: 'sent', is_read: true, created_at: new Date(Date.now() - 1000 * 60 * 20).toISOString() },
  ]

  let config = $state<EmailConfig>(MOCK_CONFIG)
  let accounts = $state<Account[]>([])
  let activeAccount = $state<Account | null>(null)
  let currentView = $state<'loading' | 'setup' | 'main'>('loading')
  let folder = $state<Folder>('inbox')
  let emails = $state<Email[]>([])
  let emailsLoading = $state(false)
  let emailsHasMore = $state(false)
  let emailsPage = $state(1)
  let selectedEmail = $state<Email | null>(null)
  let composing = $state(false)
  let showSetupInline = $state(false)
  let searchQuery = $state('')
  let readFilter = $state<'all' | 'read' | 'unread'>('all')

  let unreadCount = $state(0)

  async function loadConfig() {
    const result = await fetchApi<EmailConfig>(
      'emailGetConfig',
      { method: 'POST', body: JSON.stringify({}) },
      MOCK_CONFIG
    )
    if (result) config = result
  }

  async function loadAccounts() {
    const result = await fetchApi<Account[]>(
      'emailGetAccounts',
      { method: 'POST', body: JSON.stringify({}) },
      MOCK_ACCOUNTS
    )
    accounts = result || []
  }

  async function loadEmails(page: number = 1, append: boolean = false) {
    if (!activeAccount) return
    emailsLoading = true
    if (!append) emails = []

    const search = searchQuery.trim()
    let mockFiltered = MOCK_EMAILS.filter(e => e.folder === folder)
    if (readFilter === 'unread') mockFiltered = mockFiltered.filter(e => !e.is_read)
    else if (readFilter === 'read') mockFiltered = mockFiltered.filter(e => e.is_read)
    if (search) {
      const q = search.toLowerCase()
      mockFiltered = mockFiltered.filter(e =>
        e.from_address.toLowerCase().includes(q) ||
        e.to_address.toLowerCase().includes(q) ||
        e.subject.toLowerCase().includes(q)
      )
    }

    const mockUnread = MOCK_EMAILS.filter(e => e.folder === 'inbox' && !e.is_read).length
    const result = await fetchApi<{ emails: Email[]; hasMore: boolean; totalUnread: number }>(
      'emailGetEmails',
      { method: 'POST', body: JSON.stringify({ address: activeAccount.address, folder, page, search, readFilter }) },
      { emails: mockFiltered, hasMore: false, totalUnread: mockUnread }
    )

    if (result) {
      if (append) {
        emails = [...emails, ...result.emails]
      } else {
        emails = result.emails
      }
      emailsHasMore = result.hasMore
      unreadCount = result.totalUnread
    }

    emailsLoading = false
  }

  function handleAccountCreated(account: Account) {
    accounts = [...accounts, account]
    activeAccount = account
    currentView = 'main'
    showSetupInline = false
    folder = 'inbox'
    searchQuery = ''
    readFilter = 'all'
    emailsPage = 1
    loadEmails()
  }

  function handleAccountChange(account: Account) {
    activeAccount = account
    selectedEmail = null
    folder = 'inbox'
    searchQuery = ''
    readFilter = 'all'
    emailsPage = 1
    loadEmails()
  }

  function handleFolderChange(newFolder: Folder) {
    folder = newFolder
    selectedEmail = null
    searchQuery = ''
    readFilter = 'all'
    emailsPage = 1
    loadEmails()
  }

  function handleSearch(query: string) {
    searchQuery = query
    emailsPage = 1
    selectedEmail = null
    loadEmails()
  }

  function handleReadFilter(filter: 'all' | 'read' | 'unread') {
    readFilter = filter
    emailsPage = 1
    selectedEmail = null
    loadEmails()
  }

  function handleSelectEmail(email: Email) {
    selectedEmail = email
    if (!email.is_read) {
      emails = emails.map(e => e.id === email.id ? { ...e, is_read: true } : e)
      selectedEmail = { ...email, is_read: true }
      if (unreadCount > 0) unreadCount--
      fetchApi('emailMarkRead', { method: 'POST', body: JSON.stringify({ id: email.id }) }, { success: true })
    }
  }

  function handleLoadMore() {
    emailsPage += 1
    loadEmails(emailsPage, true)
  }

  async function handleDelete(id: number) {
    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'emailDelete',
      { method: 'POST', body: JSON.stringify({ id }) },
      { success: true }
    )

    if (result && result.success) {
      const email = emails.find(e => e.id === id)
      if (email && email.folder === 'trash') {
        emails = emails.filter(e => e.id !== id)
      } else {
        emails = emails.filter(e => e.id !== id)
      }
      selectedEmail = null
    }
  }

  async function handleDeleteAll() {
    if (!activeAccount) return

    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'emailDeleteAll',
      { method: 'POST', body: JSON.stringify({ address: activeAccount.address, folder }) },
      { success: true }
    )

    if (result && result.success) {
      selectedEmail = null
      emailsPage = 1
      loadEmails()
    }
  }

  function handleComposeSent() {
    composing = false
    if (folder === 'sent') {
      emailsPage = 1
      loadEmails()
    } else {
      folder = 'inbox'
      emailsPage = 1
      loadEmails()
    }
  }

  let unsubNui: (() => void) | null = null

  onMount(async () => {
    changeWindowTitle(localeStore.t('email_title'))
    appReady()

    await loadConfig()
    await loadAccounts()

    if (accounts.length === 0) {
      currentView = 'setup'
    } else {
      activeAccount = accounts[0]
      currentView = 'main'
      await loadEmails()
    }

    unsubNui = onNuiEvent<{ address: string; from_address: string; subject: string }>('emailNewNotification', (data) => {
      if (activeAccount && data.address === activeAccount.address && folder === 'inbox') {
        emailsPage = 1
        loadEmails()
      }
    })
  })

  onDestroy(() => {
    unsubNui?.()
  })
</script>

<div class="flex-1 flex bg-[#16171C] select-none overflow-hidden font-['Gilroy',Inter,sans-serif] relative">
  {#if currentView === 'loading'}
    <div class="flex-1 flex items-center justify-center"><div class="w-6 h-6 border-2 border-[#2D2F3A] border-t-[#7C8AED] rounded-full animate-spin"></div></div>
  {:else if currentView === 'setup' || showSetupInline}
    <EmailSetup {config} oncreated={handleAccountCreated} onback={accounts.length > 0 ? () => { showSetupInline = false; if (currentView === 'setup') { currentView = 'main'; activeAccount = accounts[0]; loadEmails(); } } : undefined} />
  {:else if currentView === 'main' && activeAccount}
    <EmailSidebar
      {accounts}
      {activeAccount}
      {config}
      onaccountchange={handleAccountChange}
      oncompose={() => { composing = true }}
      {folder}
      onfolderchange={handleFolderChange}
      {unreadCount}
      onnewaccount={() => { showSetupInline = true }}
    />

    <div class="flex-1 flex flex-col min-w-0 min-h-0">
      {#if selectedEmail}
        <EmailDetail
          email={selectedEmail}
          onback={() => { selectedEmail = null }}
          ondelete={handleDelete}
        />
      {:else}
        <EmailList
          {emails}
          loading={emailsLoading}
          hasMore={emailsHasMore}
          onselect={handleSelectEmail}
          onloadmore={handleLoadMore}
          {folder}
          {searchQuery}
          onsearch={handleSearch}
          {readFilter}
          onreadfilter={handleReadFilter}
          ondeleteall={handleDeleteAll}
        />
      {/if}
    </div>

    {#if composing}
      <EmailCompose
        fromAddress={activeAccount.address}
        onclose={() => { composing = false }}
        onsent={handleComposeSent}
      />
    {/if}
  {/if}
</div>
