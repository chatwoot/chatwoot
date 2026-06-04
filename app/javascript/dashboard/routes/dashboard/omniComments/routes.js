import { frontendURL } from '../../../helper/URLHelper';

const OmniCommentsIndex = () => import('./pages/OmniCommentsIndex.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/omni-comments'),
    name: 'omni_comments_index',
    component: OmniCommentsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
];
