export function clickOutside(
  node: HTMLElement,
  params: { callback: () => void; ignore?: string[] }
) {
  function handleClick(event: MouseEvent) {
    const target = event.target as HTMLElement
    if (!target) return

    if (node.contains(target)) return

    if (params.ignore) {
      for (const selector of params.ignore) {
        const el = document.querySelector(selector)
        if (el && el.contains(target)) return
      }
    }

    params.callback()
  }

  document.addEventListener('click', handleClick, true)

  return {
    update(newParams: { callback: () => void; ignore?: string[] }) {
      params = newParams
    },
    destroy() {
      document.removeEventListener('click', handleClick, true)
    }
  }
}
