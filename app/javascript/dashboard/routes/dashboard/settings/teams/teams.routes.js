/* eslint arrow-body-style: 0 */
import SettingsContent from '../Wrapper';
import TeamsHome from './Index';
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
          icon: 'ion-ios-people',
          newButtonRoutes: ['settings_teams_new'],
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
          component: TeamsHome,
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
              path: ':teamId/finish',
              name: 'settings_teams_finish',
              component: FinishSetup,
              roles: ['administrator'],
            },
            {
              path: ':teamId/agents',
              name: 'settings_teams_add_agents',
              roles: ['administrator'],
              component: AddAgents,
            },
          ],
        },
        {
          path: ':teamId/edit',
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
