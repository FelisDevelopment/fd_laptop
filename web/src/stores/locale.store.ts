import { MockedLocales } from '../mock/locales.mock'
import { useApi } from '../composables/useApi'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

export const useLocale = defineStore('locale', () => {
  const strings = ref<Record<string, string>>({})

  const t = computed(() => (key: string) => strings.value[key] || key)

  const fetchLocales = async () => {
    const { data } = await useApi<Record<string, string>>(
      'locales',
      {
        method: 'GET'
      },
      undefined,
      MockedLocales
    )

    if (!data.value) return

    strings.value = data.value
  }

  return {
    t,
    strings,
    fetchLocales
  }
})
