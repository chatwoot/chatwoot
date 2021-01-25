/* eslint arrow-body-style: 0 */
import SettingsContent from '../Wrapper';
import InboxHome from './Index';
import TeamStepWrap from './TeamStepWrap';
import CreateTeam from './CreateTeam';
import AddAgents from './AddAgents';
import Settings from './Settings';
import FinishSetup from './FinishSetup';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/teams'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'settings_teams_list';
        return {
          headerTitle: 'TEAMS_SETTINGS.HEADER',
          headerButtonText: 'TEAMS_SETTINGS.NEW_TEAM',
          icon: 'ion-archive',
          newButtonRoutes: ['settings_teams_list'],
          showBackButton,
        };
      },
      children: [
        {
          path: '',
          name: 'settings_teams',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'settings_teams_list',
          component: InboxHome,
          roles: ['administrator'],
        },
        {
          path: 'new',
          component: TeamStepWrap,
          children: [
            {
              path: '',
              name: 'settings_teams_new',
              component: CreateTeam,
              roles: ['administrator'],
            },
            {
              path: ':inbox_id/finish',
              name: 'settings_teams_finish',
              component: FinishSetup,
              roles: ['administrator'],
            },
            {
              path: ':team_id/agents',
              name: 'settings_teams_add_agents',
              roles: ['administrator'],
              component: AddAgents,
            },
          ],
        },
        {
          path: ':inboxId',
          name: 'settings_teams_show',
          component: Settings,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
