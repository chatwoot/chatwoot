import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import SurveyList from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/surveys'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'surveys_list',
          component: SurveyList,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
