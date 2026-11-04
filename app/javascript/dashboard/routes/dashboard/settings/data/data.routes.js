import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import Show from './Show.vue';

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
            featureFlag: FEATURE_FLAGS.DATA_IMPORT,
            permissions: ['administrator'],
          },
        },
        {
          path: ':dataImportId',
          name: 'settings_data_import_show',
          component: Show,
          meta: {
            featureFlag: FEATURE_FLAGS.DATA_IMPORT,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
