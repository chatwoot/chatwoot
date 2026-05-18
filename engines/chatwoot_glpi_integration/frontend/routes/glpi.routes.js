import { frontendURL } from 'dashboard/helper/URLHelper';

const GlpiSettings = () => import('../components/GlpiSettings.vue');

export default [
  {
    path: frontendURL('accounts/:accountId/settings/integrations/glpi'),
    name: 'glpi_integration_settings',
    meta: { permissions: ['administrator'] },
    component: GlpiSettings,
  },
];
