if (!globalThis.parentReady) {
  globalThis.parentReady = true

  const appReady = () => {
    globalThis.postMessage(
      {
        action: 'appReady',
        appId: globalThis.appId
      },
      '*'
    )
  }

  const changeWindowTitle = (newTitle) => {
    globalThis.postMessage(
      {
        action: 'changeWindowTitle',
        appId: globalThis.appId,
        data: newTitle
      },
      '*'
    )
  }

  const getAppData = () => {
    return new Promise((resolve, reject) => {
      globalThis.postMessage(
        {
          action: 'getAppData',
          appId: globalThis.appId
        },
        '*'
      )

      const rejection = setTimeout(() => {
        reject('Unable to fetch app data')
        globalThis.removeEventListener('message', handler)
      }, 5000)

      const handler = (event) => {
        const { action, data } = event.data

        if (action === `${globalThis.appId}:appData`) {
          clearTimeout(rejection)
          globalThis.removeEventListener('message', handler)

          resolve(data)
        }
      }

      globalThis.addEventListener('message', handler)
    })
  }

  const getSettings = () => {
    return new Promise((resolve, reject) => {
      globalThis.postMessage(
        {
          action: 'getSettings',
          appId: globalThis.appId
        },
        '*'
      )

      const rejection = setTimeout(() => {
        reject('Unable to fetch settings')
        globalThis.removeEventListener('message', handler)
      }, 5000)

      const handler = (event) => {
        const { action, data } = event.data

        if (action === `${globalThis.appId}:settings`) {
          clearTimeout(rejection)
          globalThis.removeEventListener('message', handler)

          resolve(data)
        }
      }

      globalThis.addEventListener('message', handler)
    })
  }

  const getNetworkSettings = () => {
    return new Promise((resolve, reject) => {
      globalThis.postMessage(
        {
          action: 'getNetworkSettings',
          appId: globalThis.appId
        },
        '*'
      )

      const rejection = setTimeout(() => {
        reject('Unable to fetch settings')
        globalThis.removeEventListener('message', handler)
      }, 5000)

      const handler = (event) => {
        const { action, data } = event.data

        if (action === `${globalThis.appId}:network`) {
          clearTimeout(rejection)
          globalThis.removeEventListener('message', handler)

          resolve(data)
        }
      }

      globalThis.addEventListener('message', handler)
    })
  }

  const getDevices = () => {
    return new Promise((resolve, reject) => {
      globalThis.postMessage(
        {
          action: 'getDevices',
          appId: globalThis.appId
        },
        '*'
      )

      const rejection = setTimeout(() => {
        reject('Unable to fetch devices')
        globalThis.removeEventListener('message', handler)
      }, 5000)

      const handler = (event) => {
        const { action, data } = event.data

        if (action === `${globalThis.appId}:devices`) {
          clearTimeout(rejection)
          globalThis.removeEventListener('message', handler)

          resolve(data)
        }
      }

      globalThis.addEventListener('message', handler)
    })
  }

  const sendNotification = (title, description) => {
    globalThis.postMessage(
      {
        action: 'sendNotification',
        appId: globalThis.appId,
        data: {
          summary: title,
          detail: description
        }
      },
      '*'
    )
  }

  const settingChangeListeners = []
  const networkChangeListeners = []
  const onSettingsChange = (cb) => {
    if (!cb) return

    settingChangeListeners.push(cb)
  }

  const onNetworkChange = (cb) => {
    if (!cb) return

    networkChangeListeners.push(cb)
  }

  const events = {
    changedSettings: (data) => {
      settingChangeListeners.forEach((cb) => cb(data))
    },
    networkChanged: (data) => {
      networkChangeListeners.forEach((cb) => cb(data))
    }
  }

  globalThis.addEventListener('message', (event) => {
    const { action, data } = event.data

    if (!events[action]) return

    events[action](data)
  })

  const getParentResourceName = () => {
    return window.resourceName
  }

  globalThis.appReady = appReady
  globalThis.changeWindowTitle = changeWindowTitle
  globalThis.getAppData = getAppData
  globalThis.getSettings = getSettings
  globalThis.onSettingsChange = onSettingsChange
  globalThis.onNetworkChange = onNetworkChange
  globalThis.sendNotification = sendNotification
  globalThis.getNetworkSettings = getNetworkSettings
  globalThis.getDevices = getDevices
  globalThis.GetParentResourceName = getParentResourceName

  globalThis.postMessage('parentReady', '*')
}
