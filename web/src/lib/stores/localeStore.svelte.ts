import type { Locale } from 'date-fns'
import { printf } from 'fast-printf'
import { MockedLocales } from '../../mock/locales.mock'
import { fetchApi } from '$lib/utils/api'
import { buildDateLocale } from '$lib/utils/buildDateLocale'

class LocaleStore {
  strings = $state<Record<string, string>>({})
  dateFnsLocale = $state<Locale>(buildDateLocale((key) => key))

  t = (key: string, ...args: unknown[]): string => {
    const str = this.strings[key] || key
    return args.length > 0 ? printf(str, ...args) : str
  }

  async fetchLocales() {
    const data = await fetchApi<Record<string, string>>(
      'locales',
      { method: 'GET' },
      MockedLocales
    )

    if (!data) return

    this.strings = data
    this.dateFnsLocale = buildDateLocale(this.t)
  }
}

export const localeStore = new LocaleStore()
