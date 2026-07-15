<script lang="ts">
  import { onMount } from 'svelte'
  import { format } from 'date-fns'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  interface CalendarEvent {
    id: number
    title: string
    description?: string
    date: string
    time?: string
    imageUrl?: string
    isShared: boolean
    isOwner?: boolean
    hasReminder?: boolean
  }

  let currentYear = $state(new Date().getFullYear())
  let currentMonth = $state(new Date().getMonth())
  let events = $state<CalendarEvent[]>([])
  let selectedDate = $state<string | null>(null)
  let showCreateModal = $state(false)
  let viewingEvent = $state<CalendarEvent | null>(null)
  let loading = $state(true)
  let deleteConfirmId = $state<number | null>(null)
  let reminderToggling = $state(false)

  let formTitle = $state('')
  let formTime = $state('')
  let formDescription = $state('')
  let formImageUrl = $state('')
  let formSubmitting = $state(false)
  let formError = $state('')

  let MONTH_NAMES = $derived(localeStore.t('date_months_wide').split(','))
  let DAY_LABELS = $derived.by(() => {
    const days = localeStore.t('date_days_abbreviated').split(',')
    return [...days.slice(1), days[0]]
  })

  const MOCK_EVENTS: CalendarEvent[] = [
    { id: 1, title: 'Server Maintenance', description: 'Scheduled downtime for updates and patches. All services will be temporarily unavailable.', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-15`, time: '02:00', isShared: true, isOwner: false, hasReminder: true },
    { id: 2, title: 'Community Meeting', description: 'Monthly community gathering to discuss updates and plans.', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-20`, time: '19:00', imageUrl: 'https://placehold.co/400x200/1E2028/F0F0F5?text=Meeting', isShared: true, isOwner: false, hasReminder: false },
    { id: 3, title: 'My Birthday', description: 'Party at my place!', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-10`, time: '18:00', isShared: false, isOwner: true, hasReminder: false },
    { id: 4, title: 'Grocery Run', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-${String(new Date().getDate()).padStart(2, '0')}`, time: '10:00', isShared: false, isOwner: true, hasReminder: true },
  ]

  let nextMockId = 100

  function getDaysInMonth(year: number, month: number): number {
    return new Date(year, month + 1, 0).getDate()
  }

  function getFirstDayOfWeek(year: number, month: number): number {
    const day = new Date(year, month, 1).getDay()
    return day === 0 ? 6 : day - 1
  }

  function formatDateKey(year: number, month: number, day: number): string {
    return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
  }

  function formatDayLabel(dateKey: string): string {
    const [y, m, d] = dateKey.substring(0, 10).split('-').map(Number)
    if (!y || !m || !d) return dateKey
    return format(new Date(y, m - 1, d), 'MMMM d, yyyy', { locale: localeStore.dateFnsLocale })
  }

  function isToday(year: number, month: number, day: number): boolean {
    const now = new Date()
    return now.getFullYear() === year && now.getMonth() === month && now.getDate() === day
  }

  let calendarDays = $derived.by(() => {
    const daysInMonth = getDaysInMonth(currentYear, currentMonth)
    const firstDay = getFirstDayOfWeek(currentYear, currentMonth)
    const days: { day: number; dateKey: string; isCurrentMonth: boolean }[] = []

    const prevMonth = currentMonth === 0 ? 11 : currentMonth - 1
    const prevYear = currentMonth === 0 ? currentYear - 1 : currentYear
    const prevDaysInMonth = getDaysInMonth(prevYear, prevMonth)
    for (let i = firstDay - 1; i >= 0; i--) {
      const d = prevDaysInMonth - i
      days.push({ day: d, dateKey: formatDateKey(prevYear, prevMonth, d), isCurrentMonth: false })
    }

    for (let d = 1; d <= daysInMonth; d++) {
      days.push({ day: d, dateKey: formatDateKey(currentYear, currentMonth, d), isCurrentMonth: true })
    }

    const remaining = 42 - days.length
    const nextMonth = currentMonth === 11 ? 0 : currentMonth + 1
    const nextYear = currentMonth === 11 ? currentYear + 1 : currentYear
    for (let d = 1; d <= remaining; d++) {
      days.push({ day: d, dateKey: formatDateKey(nextYear, nextMonth, d), isCurrentMonth: false })
    }

    return days
  })

  let eventsByDate = $derived.by(() => {
    const map: Record<string, CalendarEvent[]> = {}
    for (const ev of events) {
      const key = String(ev.date).substring(0, 10)
      if (!map[key]) map[key] = []
      map[key].push(ev)
    }
    return map
  })

  let selectedEvents = $derived.by(() => {
    if (!selectedDate) return []
    return eventsByDate[selectedDate] || []
  })

  async function loadEvents() {
    loading = true
    const mockData = MOCK_EVENTS.filter(e => {
      const d = new Date(e.date)
      return d.getMonth() === currentMonth && d.getFullYear() === currentYear
    })

    const result = await fetchApi<CalendarEvent[]>(
      'calendarGetEvents',
      { method: 'POST', body: JSON.stringify({ month: currentMonth + 1, year: currentYear }) },
      mockData
    )
    events = result || []
    loading = false
  }

  function prevMonth() {
    if (currentMonth === 0) {
      currentMonth = 11
      currentYear--
    } else {
      currentMonth--
    }
    selectedDate = null
    loadEvents()
  }

  function nextMonth() {
    if (currentMonth === 11) {
      currentMonth = 0
      currentYear++
    } else {
      currentMonth++
    }
    selectedDate = null
    loadEvents()
  }

  function goToday() {
    const now = new Date()
    currentYear = now.getFullYear()
    currentMonth = now.getMonth()
    selectedDate = formatDateKey(currentYear, currentMonth, now.getDate())
    loadEvents()
  }

  function selectDay(dateKey: string) {
    selectedDate = selectedDate === dateKey ? null : dateKey
    deleteConfirmId = null
  }

  function openEventDetail(event: CalendarEvent) {
    viewingEvent = event
    deleteConfirmId = null
  }

  function closeEventDetail() {
    viewingEvent = null
    deleteConfirmId = null
  }

  function openCreateModal() {
    formTitle = ''
    formTime = ''
    formDescription = ''
    formImageUrl = ''
    formError = ''
    showCreateModal = true
  }

  async function submitCreateEvent() {
    if (!selectedDate || !formTitle.trim() || formSubmitting) return
    formSubmitting = true

    const mockResult: CalendarEvent = {
      id: nextMockId++,
      title: formTitle.trim(),
      description: formDescription.trim() || undefined,
      date: selectedDate,
      time: formTime || undefined,
      imageUrl: formImageUrl.trim() || undefined,
      isShared: false,
      isOwner: true,
      hasReminder: false
    }

    const result = await fetchApi<CalendarEvent>(
      'calendarCreateEvent',
      { method: 'POST', body: JSON.stringify({
        title: formTitle.trim(),
        description: formDescription.trim() || null,
        date: selectedDate,
        time: formTime || null,
        imageUrl: formImageUrl.trim() || null
      })},
      mockResult
    )

    if (!result || 'error' in result) {
      formError = localeStore.t('calendar_event_save_failed')
    } else {
      events = [...events, result]
      showCreateModal = false
    }
    formSubmitting = false
  }

  async function deleteEvent(id: number) {
    const mockResult = { success: true }
    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'calendarDeleteEvent',
      { method: 'POST', body: JSON.stringify({ id }) },
      mockResult
    )

    if (result && 'success' in result) {
      events = events.filter(e => e.id !== id)
      deleteConfirmId = null
      if (viewingEvent?.id === id) {
        viewingEvent = null
      }
    }
  }

  async function toggleReminder(event: CalendarEvent) {
    if (reminderToggling) return
    reminderToggling = true

    const mockResult = { hasReminder: !event.hasReminder }
    const result = await fetchApi<{ hasReminder: boolean }>(
      'calendarToggleReminder',
      { method: 'POST', body: JSON.stringify({ eventId: event.id }) },
      mockResult
    )

    if (result && 'hasReminder' in result) {
      events = events.map(e => e.id === event.id ? { ...e, hasReminder: result.hasReminder } : e)
      if (viewingEvent?.id === event.id) {
        viewingEvent = { ...viewingEvent, hasReminder: result.hasReminder }
      }
    }
    reminderToggling = false
  }

  onMount(() => {
    changeWindowTitle(localeStore.t('calendar_title'))
    appReady()
    selectedDate = formatDateKey(currentYear, currentMonth, new Date().getDate())
    loadEvents()
  })
</script>

<div class="flex-1 flex flex-col bg-[#16171C] select-none overflow-hidden font-['Gilroy',Inter,sans-serif] relative p-4">
  <div class="flex items-center justify-between mb-3 shrink-0">
    <div class="flex items-center gap-2">
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-8 h-8 flex items-center justify-center bg-[#1E2028] border border-[#2D2F3A] rounded-lg text-[#8B8D9A] cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={prevMonth}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </button>
      <span class="text-[#F0F0F5] font-bold text-base min-w-[160px] text-center">{MONTH_NAMES[currentMonth]} {currentYear}</span>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-8 h-8 flex items-center justify-center bg-[#1E2028] border border-[#2D2F3A] rounded-lg text-[#8B8D9A] cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={nextMonth}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>
      </button>
    </div>
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button type="button" class="py-[6px] px-[14px] text-xs font-semibold text-[#8B8D9A] bg-[#1E2028] border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={goToday}>{localeStore.t('calendar_today')}</button>
  </div>

  <div class="grid grid-cols-7 gap-[2px] mb-1 shrink-0">
    {#each DAY_LABELS as label}
      <span class="text-center text-[11px] font-semibold text-[#50525E] py-1">{label}</span>
    {/each}
  </div>

  {#if loading}
    <div class="flex-1 flex items-center justify-center"><div class="w-[22px] h-[22px] border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
  {:else}
    <div class="grid grid-cols-7 gap-[2px] shrink-0">
      {#each calendarDays as { day, dateKey, isCurrentMonth }}
        {@const dayEvents = eventsByDate[dateKey] || []}
        {@const hasShared = dayEvents.some(e => e.isShared)}
        {@const hasPersonal = dayEvents.some(e => !e.isShared)}
        {@const hasReminder = dayEvents.some(e => e.hasReminder)}
        {@const isTodayCell = isCurrentMonth && isToday(currentYear, currentMonth, day)}
        {@const isSelected = selectedDate === dateKey}
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button
          type="button"
          class="aspect-square flex flex-col items-center justify-center bg-[#1E2028] border rounded-lg cursor-pointer transition-colors duration-150 relative gap-[3px] p-0 hover:bg-[#252730] hover:border-[#2D2F3A] {isCurrentMonth ? '' : 'opacity-30'} {isSelected ? '!border-[#5BBD6B] bg-[rgba(91,189,107,0.08)]' : 'border-transparent'}"
          onclick={() => selectDay(dateKey)}
        >
          <span class="text-[13px] leading-none {isTodayCell ? 'bg-[#5BBD6B] text-[#16171C] w-6 h-6 rounded-full flex items-center justify-center font-bold' : 'font-medium text-[#F0F0F5]'}">{day}</span>
          {#if dayEvents.length > 0}
            <div class="flex gap-[3px] absolute bottom-1">
              {#if hasShared}<span class="w-[5px] h-[5px] rounded-full bg-[#E4A832]"></span>{/if}
              {#if hasPersonal}<span class="w-[5px] h-[5px] rounded-full bg-[#5BBD6B]"></span>{/if}
              {#if hasReminder}<span class="w-[5px] h-[5px] rounded-full bg-[#7C8AED]"></span>{/if}
            </div>
          {/if}
        </button>
      {/each}
    </div>

    {#if selectedDate}
      <div class="flex-1 mt-2 overflow-y-auto flex flex-col gap-1 min-h-0 lscrollbar">
        <div class="flex items-center justify-between pt-2 pb-1 shrink-0">
          <span class="text-[#8B8D9A] text-[13px] font-semibold">{formatDayLabel(selectedDate)}</span>
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button type="button" class="flex items-center gap-1 py-[5px] px-3 text-xs font-semibold text-[#16171C] bg-[#5BBD6B] border-none rounded-md cursor-pointer transition-colors duration-150 hover:bg-[#4DAD5D]" onclick={openCreateModal}>
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
            {localeStore.t('calendar_new_event')}
          </button>
        </div>

        {#if selectedEvents.length === 0}
          <div class="text-[#50525E] text-[13px] text-center py-5">{localeStore.t('calendar_no_events')}</div>
        {:else}
          {#each selectedEvents as event}
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button type="button" class="bg-[#1E2028] border border-[#2D2F3A] rounded-xl overflow-hidden shrink-0 cursor-pointer transition-colors duration-150 w-full text-left hover:border-[#3A3D4A] hover:bg-[#252730]" onclick={() => openEventDetail(event)}>
              <div class="py-[10px] px-3">
                <div class="flex items-center justify-between gap-2">
                  <div class="flex items-center gap-[6px] flex-wrap min-w-0">
                    <span class="text-[#F0F0F5] text-[13px] font-semibold truncate">{event.title}</span>
                    {#if event.isShared}
                      <span class="text-[10px] font-semibold text-[#E4A832] bg-[rgba(228,168,50,0.12)] py-[2px] px-[6px] rounded shrink-0">{localeStore.t('calendar_event_shared')}</span>
                    {/if}
                    {#if event.hasReminder}
                      <span class="text-[#7C8AED] flex items-center shrink-0" title={localeStore.t('calendar_remind_me')}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                      </span>
                    {/if}
                  </div>
                  {#if event.time}
                    <span class="text-[#8B8D9A] text-xs font-semibold tabular-nums shrink-0">{event.time}</span>
                  {/if}
                </div>
              </div>
            </button>
          {/each}
        {/if}
      </div>
    {/if}
  {/if}

  {#if viewingEvent}
    <div class="absolute inset-0 z-50 flex items-center justify-center bg-[rgba(22,23,28,0.92)]">
      <div class="bg-[#1E2028] border border-[#2D2F3A] rounded-2xl w-[380px] max-w-[calc(100%-32px)] shadow-lg relative p-0 overflow-hidden max-h-[calc(100%-64px)] flex flex-col">
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="absolute top-3 right-3 w-7 h-7 flex items-center justify-center text-[#8B8D9A] bg-[rgba(22,23,28,0.6)] border-none rounded-md cursor-pointer transition-colors duration-150 z-10 hover:text-[#F0F0F5] hover:bg-[rgba(22,23,28,0.85)]" onclick={closeEventDetail}>
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>

        {#if viewingEvent.imageUrl}
          <img class="w-full h-[140px] object-cover block shrink-0" src={viewingEvent.imageUrl} alt={viewingEvent.title} />
        {/if}

        <div class="pt-4 px-5 pb-5 overflow-y-auto flex flex-col gap-3">
          <div class="flex items-center gap-2 flex-wrap">
            <h3 class="text-[#F0F0F5] font-bold text-lg leading-[1.3]">{viewingEvent.title}</h3>
            {#if viewingEvent.isShared}
              <span class="text-[10px] font-semibold text-[#E4A832] bg-[rgba(228,168,50,0.12)] py-[2px] px-[6px] rounded shrink-0">{localeStore.t('calendar_event_shared')}</span>
            {/if}
          </div>

          <div class="flex gap-4 flex-wrap">
            <div class="flex items-center gap-[6px] text-[#8B8D9A] text-[13px] font-medium">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg>
              <span>{formatDayLabel(String(viewingEvent.date))}</span>
            </div>
            {#if viewingEvent.time}
              <div class="flex items-center gap-[6px] text-[#8B8D9A] text-[13px] font-medium">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                <span>{viewingEvent.time}</span>
              </div>
            {/if}
          </div>

          {#if viewingEvent.description}
            <p class="text-[#8B8D9A] text-[13px] leading-[1.6]">{viewingEvent.description}</p>
          {/if}

          <div class="flex items-center gap-2 mt-1 flex-wrap">
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button
              type="button"
              class="flex items-center gap-[6px] py-[6px] px-3 text-xs font-semibold bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 disabled:opacity-50 disabled:cursor-default {viewingEvent.hasReminder ? 'text-[#7C8AED] !border-[#7C8AED] bg-[rgba(124,138,237,0.08)]' : 'text-[#8B8D9A] hover:text-[#7C8AED] hover:border-[#7C8AED]'}"
              onclick={() => viewingEvent && toggleReminder(viewingEvent)}
              disabled={reminderToggling}
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="{viewingEvent.hasReminder ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
              {localeStore.t('calendar_remind_me')}
            </button>

            {#if viewingEvent.isOwner && !viewingEvent.isShared}
              {#if deleteConfirmId === viewingEvent.id}
                <div class="flex items-center gap-[6px]">
                  <span class="text-[#E55B5B] text-xs font-medium">{localeStore.t('calendar_delete_confirm')}</span>
                  <!-- svelte-ignore a11y_consider_explicit_label -->
                  <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#5BBD6B] hover:border-[#5BBD6B]" onclick={() => viewingEvent && deleteEvent(viewingEvent.id)}>
                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
                  </button>
                  <!-- svelte-ignore a11y_consider_explicit_label -->
                  <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#8B8D9A] hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { deleteConfirmId = null }}>
                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                  </button>
                </div>
              {:else}
                <!-- svelte-ignore a11y_consider_explicit_label -->
                <button type="button" class="flex items-center gap-1 py-[6px] px-3 text-xs font-medium text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => viewingEvent && (deleteConfirmId = viewingEvent.id)}>
                  <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
                  {localeStore.t('calendar_event_delete')}
                </button>
              {/if}
            {/if}
          </div>
        </div>
      </div>
    </div>
  {/if}

  {#if showCreateModal}
    <div class="absolute inset-0 z-50 flex items-center justify-center bg-[rgba(22,23,28,0.92)]">
      <div class="bg-[#1E2028] border border-[#2D2F3A] rounded-2xl w-[380px] max-w-[calc(100%-32px)] p-5 shadow-lg relative">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-[#F0F0F5] font-bold text-base">{localeStore.t('calendar_new_event')}</h3>
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button type="button" class="w-7 h-7 flex items-center justify-center text-[#8B8D9A] bg-none border-none cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5]" onclick={() => { showCreateModal = false }}>
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </button>
        </div>

        <div class="flex flex-col gap-3">
          <div class="flex flex-col gap-1">
            <label class="text-[#8B8D9A] text-xs font-semibold" for="cal-title">{localeStore.t('calendar_event_title')}</label>
            <input id="cal-title" type="text" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#5BBD6B]" bind:value={formTitle} maxlength="100" />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-[#8B8D9A] text-xs font-semibold" for="cal-time">{localeStore.t('calendar_event_time')}</label>
            <input id="cal-time" type="time" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#5BBD6B]" bind:value={formTime} />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-[#8B8D9A] text-xs font-semibold" for="cal-desc">{localeStore.t('calendar_event_description')}</label>
            <textarea id="cal-desc" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#5BBD6B] resize-y min-h-[60px]" bind:value={formDescription} rows="3" maxlength="500"></textarea>
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-[#8B8D9A] text-xs font-semibold" for="cal-image">{localeStore.t('calendar_event_image')}</label>
            <input id="cal-image" type="text" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#5BBD6B]" bind:value={formImageUrl} placeholder="https://..." />
          </div>
          {#if formError}
            <span class="text-[#E55B5B] text-xs font-medium">{formError}</span>
          {/if}
          <button
            type="button"
            class="py-[10px] text-[13px] font-bold text-[#16171C] bg-[#5BBD6B] border-none rounded-lg cursor-pointer transition-colors duration-150 mt-1 enabled:hover:bg-[#4DAD5D] disabled:opacity-50 disabled:cursor-default"
            onclick={submitCreateEvent}
            disabled={!formTitle.trim() || formSubmitting}
          >
            {localeStore.t('calendar_event_save')}
          </button>
        </div>
      </div>
    </div>
  {/if}
</div>
