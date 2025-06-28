if (!globalThis.lunarContractsOverrides) {
  globalThis.lunarContractsOverrides = true

  onOpen = () => {
    const body = document.body

    const frame = body.querySelector(
      [
        'w-\\[76rem\\]',
        'h-\\[45rem\\]',
        'bg-\\[\\#0f0f0f\\]',
        'rounded-3xl',
        'border-2',
        'border-\\[\\#707070\\]',
        'p-8'
      ]
        .map((cls) => `.${cls}`)
        .join('')
    )
    if (!frame) {
      console.error('Frame not found')
      return
    }

    frame.classList.remove(
      'w-[76rem]',
      'h-[45rem]',
      'rounded-3xl',
      'border-2',
      'border-[#707070]',
      'p-8'
    )
    frame.classList.add('w-full', 'h-full', 'rounded-none', 'border-0')
  }

  globalThis.addEventListener('message', (event) => {
    const { action, data } = event.data

    if (action === 'onOpen') {
      return onOpen()
    }
  })
}
