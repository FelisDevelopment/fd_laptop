export function tooltip(node: HTMLElement, text: string) {
  let tooltipEl: HTMLDivElement | null = null

  function show() {
    if (!text) return

    tooltipEl = document.createElement('div')
    tooltipEl.textContent = text
    tooltipEl.className =
      'fixed z-[9999] rounded bg-gray-700 px-2 py-1 text-xs text-white shadow-lg pointer-events-none'

    document.body.appendChild(tooltipEl)

    const rect = node.getBoundingClientRect()
    const tipRect = tooltipEl.getBoundingClientRect()

    tooltipEl.style.left = `${rect.left + rect.width / 2 - tipRect.width / 2}px`
    tooltipEl.style.top = `${rect.top - tipRect.height - 4}px`
  }

  function hide() {
    if (tooltipEl) {
      tooltipEl.remove()
      tooltipEl = null
    }
  }

  node.addEventListener('mouseenter', show)
  node.addEventListener('mouseleave', hide)

  return {
    update(newText: string) {
      text = newText
      if (tooltipEl) {
        tooltipEl.textContent = text
      }
    },
    destroy() {
      hide()
      node.removeEventListener('mouseenter', show)
      node.removeEventListener('mouseleave', hide)
    }
  }
}
