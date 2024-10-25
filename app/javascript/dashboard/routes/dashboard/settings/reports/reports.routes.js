import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import SettingsContent from '../Wrapper.vue';
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
      component: SettingsContent,
      props: {
        headerTitle: 'OVERVIEW_REPORTS.HEADER',
        icon: 'arrow-trending-lines',
        keepAlive: false,
      },
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
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'REPORT.HEADER',
        icon: 'chat',
        keepAlive: false,
      },
      children: [
        {
          path: 'conversation',
          name: 'conversation_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: Index,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'CSAT_REPORTS.HEADER',
        icon: 'emoji',
        keepAlive: false,
      },
      children: [
        {
          path: 'csat',
          name: 'csat_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: CsatResponses,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'BOT_REPORTS.HEADER',
        icon: 'bot',
        keepAlive: false,
      },
      children: [
        {
          path: 'bot',
          name: 'bot_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
            featureFlag: FEATURE_FLAGS.RESPONSE_BOT,
          },
          component: BotReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'AGENT_REPORTS.HEADER',
        icon: 'people',
        keepAlive: false,
      },
      children: [
        {
          path: 'agent',
          name: 'agent_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: AgentReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'LABEL_REPORTS.HEADER',
        icon: 'tag',
        keepAlive: false,
      },
      children: [
        {
          path: 'label',
          name: 'label_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: LabelReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'INBOX_REPORTS.HEADER',
        icon: 'mail-inbox-all',
        keepAlive: false,
      },
      children: [
        {
          path: 'inboxes',
          name: 'inbox_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: InboxReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'TEAM_REPORTS.HEADER',
        icon: 'people-team',
      },
      children: [
        {
          path: 'teams',
          name: 'team_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
          },
          component: TeamReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'SLA_REPORTS.HEADER',
        icon: 'document-list-clock',
        keepAlive: false,
      },
      children: [
        {
          path: 'sla',
          name: 'sla_reports',
          meta: {
            permissions: ['administrator', 'report_manage'],
            featureFlag: FEATURE_FLAGS.SLA,
          },
          component: SLAReports,
        },
      ],
    },
  ],
};
