import './assets/main.css'
import 'primeicons/primeicons.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config'
import Tooltip from 'primevue/tooltip'
import { FDPreset } from './themes/fd.theme'
import Ripple from 'primevue/ripple'
import DialogService from 'primevue/dialogservice'
import ToastService from './services/toastservice/ToastService'

import App from './App.vue'

const app = createApp(App)

app.use(createPinia())
app.use(PrimeVue, {
  theme: {
    preset: FDPreset,
    options: {
      darkModeSelector: '.dark-app',
      cssLayer: {
        name: 'primevue',
        order: 'tailwind-base, primevue, tailwind-utilities'
      }
    }
  }
})
app.use(ToastService)
app.use(DialogService)
app.directive('ripple', Ripple)
app.directive('tooltip', Tooltip)

app.mount('#fdApp')
