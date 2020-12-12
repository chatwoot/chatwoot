/* eslint arrow-body-style: 0 */
import WorkflowsView from './components/WorkflowsView';
import { frontendURL } from '../../../helper/URLHelper';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/workflows'),
    name: 'workflows_dashboard',
    roles: ['administrator', 'agent'],
    component: WorkflowsView,
  },
];
