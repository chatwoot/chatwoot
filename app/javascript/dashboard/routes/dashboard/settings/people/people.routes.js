import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import PeopleHome from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/people'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'settings_people_index',
          component: PeopleHome,
          // Each tab carries its own feature flag inside the page; gating the
          // route on either one would hide the other half with it.
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
