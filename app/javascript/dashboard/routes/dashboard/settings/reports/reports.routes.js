import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');
const AgentReports = () => import('./AgentReports.vue');
const LabelReports = () => import('./LabelReports.vue');
const InboxReports = () => import('./InboxReports.vue');
const TeamReports = () => import('./TeamReports.vue');
const CsatResponses = () => import('./CsatResponses.vue');
const BotReports = () => import('./BotReports.vue');
const LiveReports = () => import('./LiveReports.vue');
const ContactReports = () => import('./ContactReports.vue');
const TrafficReports = () => import('./TrafficReports.vue');
const SLAReports = () => import('./SLAReports.vue');

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
          redirect: 'contact',
        },
        {
          path: 'overview',
          name: 'account_overview_reports',
          roles: ['administrator', 'leader'],
          component: LiveReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'CONTACT_REPORTS.HEADER',
        icon: 'contact-card-group',
        keepAlive: false,
      },
      children: [
        {
          path: 'contact',
          name: 'contact_reports',
          roles: ['administrator', 'leader'],
          component: ContactReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'TRAFFIC_REPORTS.HEADER',
        icon: 'access-time',
        keepAlive: false,
      },
      children: [
        {
          path: 'traffic',
          name: 'traffic_reports',
          roles: ['administrator', 'leader'],
          component: TrafficReports,
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
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
          roles: ['administrator', 'leader'],
          component: SLAReports,
        },
      ],
    },
  ],
};
