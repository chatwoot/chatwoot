import { frontendURL } from '../../../../helper/URLHelper';

const TeamsIndex = () => import('./Index.vue');
const CreateStepWrap = () => import('./Create/Index.vue');
const EditStepWrap = () => import('./Edit/Index.vue');
const CreateTeam = () => import('./Create/CreateTeam.vue');
const EditTeam = () => import('./Edit/EditTeam.vue');
const AddAgents = () => import('./Create/AddAgents.vue');
const EditAgents = () => import('./Edit/EditAgents.vue');
const FinishSetup = () => import('./FinishSetup.vue');
const SettingsContent = () => import('../Wrapper.vue');
const SettingsWrapper = () => import('../SettingsWrapper.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/teams'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'settings_teams_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'settings_teams_list',
          component: TeamsIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/teams'),
      component: SettingsContent,
      props: () => {
        return {
          headerTitle: 'TEAMS_SETTINGS.HEADER',
          headerButtonText: 'TEAMS_SETTINGS.NEW_TEAM',
          icon: 'people-team',
          newButtonRoutes: ['settings_teams_new'],
          showBackButton: true,
        };
      },
      children: [
        {
          path: 'new',
          component: CreateStepWrap,
          children: [
            {
              path: '',
              name: 'settings_teams_new',
              component: CreateTeam,
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: ':teamId/finish',
              name: 'settings_teams_finish',
              component: FinishSetup,
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: ':teamId/agents',
              name: 'settings_teams_add_agents',
              meta: {
                permissions: ['administrator'],
              },
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
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: 'agents',
              name: 'settings_teams_edit_members',
              component: EditAgents,
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: 'finish',
              name: 'settings_teams_edit_finish',
              meta: {
                permissions: ['administrator'],
              },
              component: FinishSetup,
            },
          ],
        },
      ],
    },
  ],
};
