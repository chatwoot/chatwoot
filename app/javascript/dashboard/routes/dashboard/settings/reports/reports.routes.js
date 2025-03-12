import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import ReportsWrapper from './components/ReportsWrapper.vue';
import Index from './Index.vue';
import AgentReports from './AgentReports.vue';
import LabelReports from './LabelReports.vue';
import InboxReports from './InboxReports.vue';
import TeamReports from './TeamReports.vue';
import CsatResponses from './CsatResponses.vue';
import BotReports from './BotReports.vue';
import LiveReports from './LiveReports.vue';
import SLAReports from './SLAReports.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: ReportsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'account_overview_reports', params: to.params };
          },
        },
        {
          path: 'overview',
          name: 'account_overview_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: LiveReports,
        },
        {
          path: 'conversation',
          name: 'conversation_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: Index,
        },
        {
          path: 'agent',
          name: 'agent_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: AgentReports,
        },
        {
          path: 'label',
          name: 'label_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: LabelReports,
        },
        {
          path: 'inboxes',
          name: 'inbox_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: InboxReports,
        },
        {
          path: 'teams',
          name: 'team_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: TeamReports,
        },
        {
          path: 'sla',
          name: 'sla_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
            featureFlag: FEATURE_FLAGS.SLA,
          },
          component: SLAReports,
        },
        {
          path: 'csat',
          name: 'csat_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: CsatResponses,
        },
        {
          path: 'bot',
          name: 'bot_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: BotReports,
        },
      ],
    },
  ],
};
