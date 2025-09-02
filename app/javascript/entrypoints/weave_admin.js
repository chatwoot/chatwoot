import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';
import vuetify from 'weave/plugins/vuetify';
import MasterAdminDashboard from 'weave/admin/MasterAdminDashboard.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en_GB',
  fallbackLocale: 'en',
  messages: { 
    en: {
      tenants: 'Tenants',
      alerts: 'Alerts',
      actions: 'Actions',
      suspend: 'Suspend',
      upgrade: 'Upgrade',
      grantBenefit: 'Grant Benefit'
    } 
  },
});

window.onload = () => {
  const el = document.querySelector('#app');
  if (!el) return;
  
  const app = createApp(MasterAdminDashboard);
  app.use(i18n);
  app.use(vuetify);
  app.mount('#app');
};

