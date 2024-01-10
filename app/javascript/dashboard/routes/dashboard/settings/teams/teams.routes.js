/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../../helper/URLHelper';

const CreateStepWrap = () => import('./Create/Index.vue');
const EditStepWrap = () => import('./Edit/Index.vue');
const CreateTeam = () => import('./Create/CreateTeam.vue');
const EditTeam = () => import('./Edit/EditTeam.vue');
const AddAgents = () => import('./Create/AddAgents.vue');
const EditAgents = () => import('./Edit/EditAgents.vue');
const FinishSetup = () => import('./FinishSetup.vue');
const SettingsContent = () => import('../Wrapper.vue');
const TeamsHome = () => import('./Index.vue');

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
          icon: 'people-team',
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
