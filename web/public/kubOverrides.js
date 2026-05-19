if (!globalThis.kubOverridesLoaded) {
  globalThis.kubOverridesLoaded = true

  function applyOverrides() {
    const body = document.body

    const lastChild = body.lastElementChild
    if (lastChild) {
      lastChild.setAttribute(
        'style',
        'position:relative; margin: 0; left: 0; top: 0; width: 100vw; height: 100vh; max-height: auto; max-width: auto; transform: none;'
      )
    }

    const head = document.head
    if (!head.querySelector('#kub-override-style')) {
      const style = head.appendChild(document.createElement('style'))
      style.id = 'kub-override-style'
      style.setAttribute('type', 'text/css')
      style.appendChild(
        document.createTextNode(
          '.border-image { border-image: unset !important; } .ipad{border: unset !important;} .ipad::after{display:none !important;} ' +
          'div[x-data*="initTabletData"] { width: 100% !important; height: 100% !important; position: relative !important; transform: none !important; top: 0 !important; left: 0 !important; margin: 0 !important; } ' +
          'div[x-show="isVisible"] { position: absolute !important; width: 100% !important; height: 100% !important; max-height: 100% !important; max-width: 100% !important; transform: none !important; top: 0 !important; left: 0 !important; margin: 0 !important; border-radius: 0 !important; box-shadow: none !important; } ' +
          '.ipad-border { display: none !important; }'
        )
      )
    }
  }

  globalThis.addEventListener('message', (event) => {
    const { type, action } = event.data || {}

    if (type === 'showUI' || type === 'setVisibility' || action === 'onOpen') {
      applyOverrides()
    }
  })
}
