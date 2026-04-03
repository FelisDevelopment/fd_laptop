if (!globalThis.raheOverridesLoaded) {
  globalThis.raheOverridesLoaded = true

  function applyOverrides() {
    const body = document.body

    const firstChild = body.firstElementChild
    if (firstChild) {
      firstChild.setAttribute(
        'style',
        'position:relative; margin: 0; left: 0; top: 0; width: 100%; height: 100%;'
      )
    }

    const tabletFrame = body.getElementsByClassName('tablet-frame')[0]
    if (tabletFrame) {
      tabletFrame.remove()
    }
  }

  function removeOverrides() {
    // rahe apps clean up on their own hideMenu message
  }

  globalThis.addEventListener('message', (event) => {
    const { action } = event.data || {}

    if (action === 'showMenu' || action === 'onOpen') {
      applyOverrides()
    }
  })
}
