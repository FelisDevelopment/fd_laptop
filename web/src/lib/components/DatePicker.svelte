<script lang="ts">
  import { fetchApi } from '$lib/utils/api'
  import { localeStore } from '$lib/stores/localeStore.svelte'

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

  const MOCK_EVENTS: CalendarEvent[] = [
    { id: 1, title: 'Server Maintenance', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-15`, time: '02:00', isShared: true, isOwner: false },
    { id: 2, title: 'Community Meeting', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-20`, time: '19:00', isShared: true, isOwner: false },
    { id: 3, title: 'My Birthday', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-10`, time: '18:00', isShared: false, isOwner: true },
    { id: 4, title: 'Grocery Run', date: `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-${String(new Date().getDate()).padStart(2, '0')}`, time: '10:00', isShared: false, isOwner: true },
  ]

  let now = $state(new Date())
  let viewMonth = $state(now.getMonth())
  let viewYear = $state(now.getFullYear())
  let selectedDay = $state<number | null>(now.getDate())
  let events = $state<CalendarEvent[]>([])
  let loading = $state(false)

  let monthNames = $derived(localeStore.t('date_months_wide').split(','))
  let dayNames = $derived(localeStore.t('date_days_abbreviated').split(','))

  function getDaysInMonth(month: number, year: number) {
    return new Date(year, month + 1, 0).getDate()
  }

  function getFirstDayOfMonth(month: number, year: number) {
    return new Date(year, month, 1).getDay()
  }

  function formatDateKey(year: number, month: number, day: number): string {
    return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
  }

  let days = $derived.by(() => {
    const totalDays = getDaysInMonth(viewMonth, viewYear)
    const firstDay = getFirstDayOfMonth(viewMonth, viewYear)
    const cells: (number | null)[] = []

    for (let i = 0; i < firstDay; i++) cells.push(null)
    for (let i = 1; i <= totalDays; i++) cells.push(i)

    return cells
  })

  let eventsByDate = $derived.by(() => {
    const map: Record<string, CalendarEvent[]> = {}
    for (const ev of events) {
      const key = ev.date.substring(0, 10)
      if (!map[key]) map[key] = []
      map[key].push(ev)
    }
    return map
  })

  let selectedDateEvents = $derived.by(() => {
    if (selectedDay === null) return []
    const key = formatDateKey(viewYear, viewMonth, selectedDay)
    return eventsByDate[key] || []
  })

  function isToday(day: number | null): boolean {
    if (!day) return false
    const today = new Date()
    return day === today.getDate() && viewMonth === today.getMonth() && viewYear === today.getFullYear()
  }

  function hasEvents(day: number | null): CalendarEvent[] | null {
    if (!day) return null
    const key = formatDateKey(viewYear, viewMonth, day)
    return eventsByDate[key]?.length ? eventsByDate[key] : null
  }

  async function loadEvents() {
    loading = true
    const mockData = MOCK_EVENTS.filter(e => {
      const d = new Date(e.date)
      return d.getMonth() === viewMonth && d.getFullYear() === viewYear
    })

    const result = await fetchApi<CalendarEvent[]>(
      'calendarGetEvents',
      { method: 'POST', body: JSON.stringify({ month: viewMonth + 1, year: viewYear }) },
      mockData
    )
    events = result || []
    loading = false
  }

  function prevMonth() {
    if (viewMonth === 0) {
      viewMonth = 11
      viewYear--
    } else {
      viewMonth--
    }
    selectedDay = null
    loadEvents()
  }

  function nextMonth() {
    if (viewMonth === 11) {
      viewMonth = 0
      viewYear++
    } else {
      viewMonth++
    }
    selectedDay = null
    loadEvents()
  }

  function selectDay(day: number | null) {
    if (!day) return
    selectedDay = selectedDay === day ? null : day
  }

  loadEvents()
</script>

<div class="w-[264px] bg-[#1E2028] rounded-xl p-[14px] shadow-lg font-['Gilroy',Inter,sans-serif] select-none">
  <div class="flex items-center justify-between mb-[10px]">
    <button
      type="button"
      aria-label="Previous month"
      class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-lg text-[#8B8D9A] cursor-pointer transition-colors duration-150 hover:bg-white/[0.08] hover:text-[#F0F0F5]"
      onclick={prevMonth}
    >
      <i class="fa-solid fa-chevron-left text-xs"></i>
    </button>
    <span class="text-[13px] font-semibold text-[#F0F0F5]">{monthNames[viewMonth]} {viewYear}</span>
    <button
      type="button"
      aria-label="Next month"
      class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-lg text-[#8B8D9A] cursor-pointer transition-colors duration-150 hover:bg-white/[0.08] hover:text-[#F0F0F5]"
      onclick={nextMonth}
    >
      <i class="fa-solid fa-chevron-right text-xs"></i>
    </button>
  </div>

  <div class="grid grid-cols-7 gap-[2px] text-center">
    {#each dayNames as dayName}
      <div class="text-[10px] font-semibold text-[#50525E] py-1">{dayName}</div>
    {/each}
    {#each days as day}
      {@const today = isToday(day)}
      {@const dayEvents = hasEvents(day)}
      {@const isSelected = day !== null && selectedDay === day}
      <button
        type="button"
        class="relative flex flex-col items-center justify-center text-xs border-none rounded-lg py-1 pb-[6px] min-h-[28px] transition-colors duration-150 {day === null ? 'cursor-default bg-none text-[#F0F0F5]' : today ? 'bg-[#7C8AED] font-bold text-white cursor-pointer hover:bg-[#6B7ADB]' : isSelected ? 'bg-[rgba(124,138,237,0.15)] text-[#F0F0F5] cursor-pointer hover:bg-[rgba(124,138,237,0.15)]' : 'bg-none text-[#F0F0F5] cursor-pointer hover:bg-white/[0.06]'}"
        onclick={() => selectDay(day)}
        disabled={day === null}
      >
        <span>{day ?? ''}</span>
        {#if dayEvents}
          <div class="flex gap-[2px] absolute bottom-px">
            {#if dayEvents.some(e => e.isShared)}<span class="w-1 h-1 rounded-full bg-[#E4A832]"></span>{/if}
            {#if dayEvents.some(e => !e.isShared)}<span class="w-1 h-1 rounded-full bg-[#5BBD6B]"></span>{/if}
          </div>
        {/if}
      </button>
    {/each}
  </div>

  {#if selectedDay !== null && selectedDateEvents.length > 0}
    <div class="mt-[10px] pt-[10px] border-t border-[#2D2F3A] flex flex-col gap-[6px] max-h-[120px] overflow-y-auto">
      {#each selectedDateEvents as event}
        <div class="flex items-center gap-[6px] px-[2px]">
          <span class="w-[6px] h-[6px] rounded-full shrink-0 {event.isShared ? 'bg-[#E4A832]' : 'bg-[#5BBD6B]'}"></span>
          <span class="flex-1 min-w-0 text-[11px] font-medium text-[#C8C9CF] truncate">{event.title}</span>
          {#if event.time}
            <span class="text-[10px] font-semibold text-[#50525E] tabular-nums shrink-0">{event.time}</span>
          {/if}
        </div>
      {/each}
    </div>
  {:else if selectedDay !== null}
    <div class="mt-[10px] pt-[10px] border-t border-[#2D2F3A] text-[11px] text-[#50525E] text-center pb-[2px]">{localeStore.t('calendar_no_events')}</div>
  {/if}
</div>
