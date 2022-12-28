import SettingsContent from '../Wrapper';
import Automation from './Index';
const AddAutomation = () => import('./AddAutomationRule.vue');
const EditAutomation = () => import('./EditAutomationRule.vue');
import { frontendURL } from 'dashboard/helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/automations'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'automation_list';
        return {
          headerTitle: 'AUTOMATION.HEADER',
          headerButtonText: 'AUTOMATION.HEADER_BTN_TXT',
          icon: 'automation',
          showBackButton,
        };
      },
      children: [
        {
          path: '',
          name: 'automation_list',
          component: Automation,
          roles: ['administrator', 'agent'],
        },
        {
          path: 'new',
          name: 'automation_new',
          component: AddAutomation,
          roles: ['administrator', 'agent'],
        },
        {
          path: ':automationId/edit',
          name: 'automation_edit',
          component: EditAutomation,
          roles: ['administrator', 'agent'],
        },
      ],
    },
  ],
};
