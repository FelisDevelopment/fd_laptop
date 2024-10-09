<script setup lang="ts">
import { useLaptop } from '../../stores/laptop.store'
import { onClickOutside, useDateFormat, useNow } from '@vueuse/core'
import { computed, ref } from 'vue'
import DatePicker from 'primevue/datepicker'

const laptop = useLaptop()
const isOpen = ref<boolean>(false)
const calendar = ref<HTMLDivElement>()
const now = useNow()

const getClock = computed(() => {
  let format = 'hh:mm A'

  if (laptop.clock24h) {
    format = 'HH:mm'
  }

  if (laptop.useServerTime) {
    return laptop.formattedServerTime
  }

  return useDateFormat(now, format, { locales: laptop.dateLocale })
})

const getDate = computed(() => {
  return useDateFormat(now, laptop.dateFormat, { locales: laptop.dateLocale })
})

onClickOutside(
  calendar,
  () => {
    isOpen.value = false
  },
  {
    ignore: ['#clock-button']
  }
)
</script>
<template>
  <Transition
    name="custom"
    enter-active-class="transition ease-out duration-300"
    enter-from-class="opacity-0 translate-y-5"
    enter-to-class="opacity-100 translate-y-0"
    leave-active-class="transition ease-in duration-125"
    leave-from-class="opacity-100 translate-y-0"
    leave-to-class="opacity-0 translate-y-5"
  >
    <div v-if="isOpen" class="absolute bottom-16 right-0 z-50" ref="calendar">
      <DatePicker inline />
    </div>
  </Transition>
  <button
    @click.prevent="isOpen = !isOpen"
    id="clock-button"
    type="button"
    class="flex h-8 flex-col items-center justify-center rounded px-2 text-xs font-medium transition duration-150 hover:bg-white/50 focus:outline-none active:scale-90 active:bg-white dark:hover:bg-black/25 dark:active:bg-black/50"
  >
    <span class="block">{{ getClock }}</span>
    <span class="block">{{ getDate }}</span>
  </button>
</template>
