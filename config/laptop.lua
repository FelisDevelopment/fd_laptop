return {
    debug = false,

    -- Use server time, instead of real-life time.
    useServerTime = true,

    -- This represents if clock is in 24h or 12h format. true = 24h, false = 12h
    -- Default is 24h
    clock24h = true,

    -- Date formating. Under the hood, uses `date-fns` (https://date-fns.org/docs/format)
    dateFormat = 'MMM dd, yyyy',
    dateLocale = 'en-US',
}
