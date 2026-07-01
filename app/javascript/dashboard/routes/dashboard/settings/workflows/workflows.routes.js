import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const WorkflowsIndex = () => import('./Index.vue');
const WorkflowBuilder = () => import('./Builder.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/workflows'),
      component: SettingsContent,
      props: {
        headerTitle: 'WORKFLOWS.HEADER',
        icon: 'share-network',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'workflows_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'workflows_list',
          component: WorkflowsIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'new',
          name: 'workflows_new',
          component: WorkflowBuilder,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':workflowId/edit',
          name: 'workflows_edit',
          component: WorkflowBuilder,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
