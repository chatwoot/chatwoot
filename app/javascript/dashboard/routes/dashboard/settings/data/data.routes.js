import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import Show from './Show.vue';
import ExportShow from './ExportShow.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/data'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'settings_data_imports',
          component: Index,
          meta: {
            permissions: ['administrator', 'contact_manage'],
            reuseOnQueryChange: true,
          },
        },
        {
          path: 'exports/:dataExportId',
          name: 'settings_data_export_show',
          component: ExportShow,
          meta: { permissions: ['administrator', 'contact_manage'] },
        },
        {
          path: ':dataImportId',
          name: 'settings_data_import_show',
          component: Show,
          meta: {
            permissions: ['administrator', 'contact_manage'],
          },
        },
      ],
    },
  ],
};
