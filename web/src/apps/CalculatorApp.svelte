<script lang="ts">
  import { onMount } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  let display = $state('0')
  let formula = $state('')
  let previousValue = $state<number | null>(null)
  let operator = $state<string | null>(null)
  let waitingForOperand = $state(false)

  const operatorSymbol: Record<string, string> = {
    '+': '+',
    '-': '\u2212',
    '*': '\u00d7',
    '/': '\u00f7'
  }

  function inputDigit(digit: string) {
    if (waitingForOperand) {
      display = digit
      waitingForOperand = false
    } else {
      display = display === '0' ? digit : display + digit
    }
  }

  function inputDecimal() {
    if (waitingForOperand) {
      display = '0.'
      waitingForOperand = false
      return
    }
    if (!display.includes('.')) {
      display = display + '.'
    }
  }

  function clear() {
    display = '0'
    formula = ''
    previousValue = null
    operator = null
    waitingForOperand = false
  }

  function toggleSign() {
    const value = parseFloat(display)
    if (value !== 0) {
      display = String(-value)
    }
  }

  function inputPercent() {
    const value = parseFloat(display)
    display = String(value / 100)
  }

  function calculate(left: number, right: number, op: string): number {
    switch (op) {
      case '+': return left + right
      case '-': return left - right
      case '*': return left * right
      case '/': return right !== 0 ? left / right : 0
      default: return right
    }
  }

  function handleOperator(nextOperator: string) {
    const current = parseFloat(display)

    if (previousValue !== null && operator && !waitingForOperand) {
      const result = calculate(previousValue, current, operator)
      formula = String(parseFloat(result.toFixed(10))) + ' ' + operatorSymbol[nextOperator]
      display = String(parseFloat(result.toFixed(10)))
      previousValue = result
    } else {
      previousValue = current
      formula = display + ' ' + operatorSymbol[nextOperator]
    }

    operator = nextOperator
    waitingForOperand = true
  }

  function handleEquals() {
    if (previousValue === null || !operator) return

    const current = parseFloat(display)
    const result = calculate(previousValue, current, operator)
    formula = formula + ' ' + display + ' ='
    display = String(parseFloat(result.toFixed(10)))
    previousValue = null
    operator = null
    waitingForOperand = true
  }

  const buttons = [
    { label: 'C', action: clear, style: 'function' },
    { label: '+/-', action: toggleSign, style: 'function' },
    { label: '%', action: inputPercent, style: 'function' },
    { label: '/', action: () => handleOperator('/'), style: 'operator' },
    { label: '7', action: () => inputDigit('7'), style: 'digit' },
    { label: '8', action: () => inputDigit('8'), style: 'digit' },
    { label: '9', action: () => inputDigit('9'), style: 'digit' },
    { label: '*', action: () => handleOperator('*'), style: 'operator' },
    { label: '4', action: () => inputDigit('4'), style: 'digit' },
    { label: '5', action: () => inputDigit('5'), style: 'digit' },
    { label: '6', action: () => inputDigit('6'), style: 'digit' },
    { label: '-', action: () => handleOperator('-'), style: 'operator' },
    { label: '1', action: () => inputDigit('1'), style: 'digit' },
    { label: '2', action: () => inputDigit('2'), style: 'digit' },
    { label: '3', action: () => inputDigit('3'), style: 'digit' },
    { label: '+', action: () => handleOperator('+'), style: 'operator' },
    { label: '0', action: () => inputDigit('0'), style: 'digit wide' },
    { label: '.', action: inputDecimal, style: 'digit' },
    { label: '=', action: handleEquals, style: 'operator' }
  ]

  onMount(() => {
    changeWindowTitle(localeStore.t('calculator_title'))
    appReady()
  })
</script>

<div class="flex flex-1 flex-col select-none overflow-hidden bg-[#16171C]">
  <div class="flex flex-col items-end justify-end px-5 py-4 min-h-[80px]">
    <span class="text-[#8B8D9A] truncate text-sm min-h-[20px]">{formula}</span>
    <span class="text-[#F0F0F5] truncate text-4xl font-light">{display}</span>
  </div>

  <div class="grid flex-1 grid-cols-4 gap-[6px] p-3 pt-0">
    {#each buttons as btn}
      <button
        type="button"
        class="flex items-center justify-center rounded-lg text-lg font-medium transition-colors active:brightness-90
          {btn.style === 'operator'
            ? 'bg-[#E4A832] text-[#16171C] hover:bg-[#EDB64A]'
            : btn.style === 'function'
              ? 'bg-[#2D2F3A] text-[#F0F0F5] hover:bg-[#3a3c4a]'
              : 'bg-[#1E2028] text-[#F0F0F5] hover:bg-[#252730]'}
          {btn.style.includes('wide') ? 'col-span-2' : ''}"
        onclick={btn.action}
      >
        {btn.label === '*' ? '\u00d7' : btn.label === '/' ? '\u00f7' : btn.label}
      </button>
    {/each}
  </div>
</div>
