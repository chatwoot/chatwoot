/* eslint arrow-body-style: 0 */
import SettingsContent from '../Wrapper';
import InboxHome from './Index';
import CreateStepWrap from './Create/Index';
import EditStepWrap from './Edit/Index';
import CreateTeam from './Create/CreateTeam';
import EditTeam from './Edit/EditTeam';
import AddAgents from './Create/AddAgents';
import EditAgents from './Edit/EditAgents';
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
          component: CreateStepWrap,
          children: [
            {
              path: '',
              name: 'settings_teams_new',
              component: CreateTeam,
              roles: ['administrator'],
            },
            {
              path: ':team_id/finish',
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
          path: ':team_id/edit',
          component: EditStepWrap,
          children: [
            {
              path: '',
              name: 'settings_teams_edit',
              component: EditTeam,
              roles: ['administrator'],
            },
            {
              path: 'agents',
              name: 'settings_teams_edit_members',
              component: EditAgents,
              roles: ['administrator'],
            },
            {
              path: 'finish',
              name: 'settings_teams_edit_finish',
              roles: ['administrator'],
              component: FinishSetup,
            },
          ],
        },
      ],
    },
  ],
};
