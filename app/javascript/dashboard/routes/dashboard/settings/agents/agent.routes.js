import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agents'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'agent_list', params: to.params };
          },
        },
        {
          // Agents and teams now share one page; the old paths stay as
          // redirects so existing bookmarks and deep links keep working.
          path: 'list',
          name: 'agent_list',
          redirect: to => ({
            name: 'settings_people_index',
            params: to.params,
            query: { tab: 'agents' },
          }),
        },
      ],
    },
  ],
};
