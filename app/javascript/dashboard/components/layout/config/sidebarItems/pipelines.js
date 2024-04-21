import { frontendURL } from '../../../../helper/URLHelper';

const pipelines = accountId => ({
  parentNav: 'pipelines',
  routes: ['pipelines_dashboard'],
  menuItems: [
    {
      icon: 'pipeline-card-group',
      label: 'DEFAULT_PIPELINE',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/pipelines`),
      toStateName: 'pipelines_dashboard',
    },
  ],
});

export default pipelines;
