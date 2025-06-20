import { frontendURL } from 'dashboard/helper/URLHelper';
import Applications from './Index.vue';
import ApplicationModal from './components/ApplicationModal.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/applications/list'),
      name: 'applications_list',
      component: Applications,
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/applications/new'),
      name: 'applications_new',
      component: ApplicationModal,
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL(
        'accounts/:accountId/settings/applications/:applicationId/edit'
      ),
      name: 'applications_edit',
      component: ApplicationModal,
      meta: {
        permissions: ['administrator'],
      },
    },
  ],
};
