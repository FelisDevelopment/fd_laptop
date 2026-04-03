<script lang="ts">
  import { format } from 'date-fns'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { clickOutside } from '$lib/utils/clickOutside'
  import DatePicker from '$lib/components/DatePicker.svelte'

  let isOpen = $state(false)
  let calendarRef = $state<HTMLDivElement | null>(null)

  let now = $state(new Date())

  $effect(() => {
    const interval = setInterval(() => {
      now = new Date()
    }, 1000)

    return () => clearInterval(interval)
  })

  let getClock = $derived.by(() => {
    if (laptopStore.useServerTime) {
      return laptopStore.formattedServerTime
    }

    let clockFormat = 'hh:mm a'
    if (laptopStore.clock24h) {
      clockFormat = 'HH:mm'
    }

    return format(now, clockFormat, { locale: localeStore.dateFnsLocale })
  })

  let getDate = $derived(format(now, laptopStore.dateFormat, { locale: localeStore.dateFnsLocale }))
</script>

{#if isOpen}
  <div
    class="absolute bottom-16 right-0 z-50"
    bind:this={calendarRef}
    use:clickOutside={{ callback: () => isOpen = false, ignore: ['#clock-button'] }}
  >
    <DatePicker />
  </div>
{/if}
<button
  onclick={() => isOpen = !isOpen}
  id="clock-button"
  type="button"
  class="flex h-8 flex-col items-center justify-center rounded-lg px-2.5 text-xs font-medium transition-colors hover:bg-white/10 focus:outline-none active:scale-95 active:bg-white/15"
>
  <span class="block">{getClock}</span>
  <span class="block">{getDate}</span>
</button>
