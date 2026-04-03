import type { Locale, FormatDistanceToken } from 'date-fns'
import type { FormatRelativeToken, LocaleDayPeriod } from 'date-fns/locale'

const distanceTokenToKey: Record<FormatDistanceToken, string> = {
  lessThanXSeconds: 'date_distance_less_than_x_seconds',
  xSeconds: 'date_distance_x_seconds',
  halfAMinute: 'date_distance_half_a_minute',
  lessThanXMinutes: 'date_distance_less_than_x_minutes',
  xMinutes: 'date_distance_x_minutes',
  aboutXHours: 'date_distance_about_x_hours',
  xHours: 'date_distance_x_hours',
  xDays: 'date_distance_x_days',
  aboutXWeeks: 'date_distance_about_x_weeks',
  xWeeks: 'date_distance_x_weeks',
  aboutXMonths: 'date_distance_about_x_months',
  xMonths: 'date_distance_x_months',
  aboutXYears: 'date_distance_about_x_years',
  xYears: 'date_distance_x_years',
  overXYears: 'date_distance_over_x_years',
  almostXYears: 'date_distance_almost_x_years'
}

const relativeTokenFormats: Record<FormatRelativeToken, string> = {
  lastWeek: "'last' eeee 'at' p",
  yesterday: "'yesterday at' p",
  today: "'today at' p",
  tomorrow: "'tomorrow at' p",
  nextWeek: "eeee 'at' p",
  other: 'P'
}

function splitList(value: string | undefined, expected: number): string[] {
  const items = (value || '').split(',')
  return items.length === expected ? items : []
}

function pickWidth(
  widths: Record<string, string[]>,
  index: number,
  width?: string
): string {
  const list = widths[width || 'abbreviated'] || widths['abbreviated']
  return list[index] || ''
}

const nullMatch = () => null

export function buildDateLocale(t: (key: string) => string): Locale {
  const monthsWide = splitList(t('date_months_wide'), 12)
  const monthsAbbr = splitList(t('date_months_abbreviated'), 12)
  const daysWide = splitList(t('date_days_wide'), 7)
  const daysAbbr = splitList(t('date_days_abbreviated'), 7)

  return {
    code: 'custom',

    formatDistance(token, count, options) {
      const key = distanceTokenToKey[token]
      let result = key
        ? t(key).replace('{{count}}', String(count))
        : `${count}`

      if (options?.addSuffix) {
        const suffixKey =
          options.comparison && options.comparison > 0
            ? 'date_distance_suffix_future'
            : 'date_distance_suffix_ago'
        result = t(suffixKey).replace('{{time}}', result)
      }

      return result
    },

    formatRelative(token) {
      return relativeTokenFormats[token]
    },

    localize: {
      ordinalNumber: (n) => String(n),
      era: () => '',
      quarter: () => '',
      month: (n, options) =>
        pickWidth({ wide: monthsWide, abbreviated: monthsAbbr }, n, options?.width),
      day: (n, options) =>
        pickWidth({ wide: daysWide, abbreviated: daysAbbr }, n, options?.width),
      dayPeriod: (period: LocaleDayPeriod) => {
        if (period === 'am') return t('date_am')
        if (period === 'pm') return t('date_pm')
        return ''
      }
    },

    formatLong: {
      date: () => 'MM/dd/yyyy',
      time: () => 'HH:mm:ss',
      dateTime: () => 'MM/dd/yyyy HH:mm:ss'
    },

    match: {
      ordinalNumber: nullMatch,
      era: nullMatch,
      quarter: nullMatch,
      month: nullMatch,
      day: nullMatch,
      dayPeriod: nullMatch
    },

    options: {
      weekStartsOn: 0,
      firstWeekContainsDate: 1
    }
  }
}
