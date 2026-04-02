import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import TemplatesHome from './Index.vue';
import TemplateBuilderPage from './TemplateBuilderPage.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/templates'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'templates_list',
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.TEMPLATE_BUILDER,
          },
          component: TemplatesHome,
        },
        {
          path: 'builder',
          name: 'template_builder',
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.TEMPLATE_BUILDER,
          },
          component: TemplateBuilderPage,
        },
      ],
    },
  ],
};
