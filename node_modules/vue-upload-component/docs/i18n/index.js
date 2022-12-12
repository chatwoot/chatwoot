// import Vue from 'vue'
import VueI18n from 'vue-i18n'
import en from './en'
import zhCN from './zh-cn'

// Vue.use(VueI18n)

export default new VueI18n({
  locale: 'en',
  messages: {
    'zh-cn': zhCN,
    en,
  }
})
