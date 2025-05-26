import { createApp } from 'vue'
import { createVueDapp } from 'vue-dapp'
import App from './App.vue'
import './style.css'

const app = createApp(App)

// 配置VueDapp
const vueDapp = createVueDapp({
  autoConnect: true,
  dappMetadata: {
    name: 'Permit2 Token Bank',
    url: window.location.origin
  }
})

app.use(vueDapp)
app.mount('#app') 