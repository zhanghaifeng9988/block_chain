import { createApp } from 'vue'
import { createVueDapp } from 'vue-dapp'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import './style.css'
import App from './App.vue'

const app = createApp(App)

app.use(createVueDapp({
  autoConnect: true,
  dappConfig: {
    walletConnectProjectId: 'YOUR_PROJECT_ID', // 需要替换为实际的 Project ID
  }
}))
app.use(ElementPlus)

app.mount('#app')
