import { AdminSupervisorRoles } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');
const AgentReports = () => import('./AgentReports.vue');
const LabelReports = () => import('./LabelReports.vue');
const InboxReports = () => import('./InboxReports.vue');
const TeamReports = () => import('./TeamReports.vue');
const CsatResponses = () => import('./CsatResponses.vue');
const LiveReports = () => import('./LiveReports.vue');
const TriggerReports = () => import('./TriggerReports.vue');
const InvoiceReports = () => import('./InvoiceReports.vue');
const TicketsReports = () => import('./TicketsReports.vue');

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
          redirect: 'overview',
        },
        {
          path: 'overview',
          name: 'account_overview_reports',
          roles: AdminSupervisorRoles,
          component: LiveReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'TRIGGER_REPORTS.HEADER',
        icon: 'arrow-trending-lines',
        keepAlive: false,
      },
      children: [
        {
          path: 'triggers',
          name: 'triggers_reports',
          roles: AdminSupervisorRoles,
          component: TriggerReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      name: 'invoice_reports',
      props: {
        headerTitle: 'INVOICE_REPORTS.HEADER',
        icon: 'invoice',
        keepAlive: false,
      },
      children: [
        {
          path: 'invoices',
          name: 'invoice_reports_dashboard',
          roles: AdminSupervisorRoles,
          component: InvoiceReports,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports/tickets'),
      component: SettingsContent,
      props: {
        headerTitle: 'TICKETS_REPORTS.HEADER',
        icon: 'ticket',
        keepAlive: false,
      },
      children: [
        {
          path: '',
          name: 'tickets_reports',
          roles: AdminSupervisorRoles,
          component: TicketsReports,
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
          roles: AdminSupervisorRoles,
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
          roles: AdminSupervisorRoles,
          component: CsatResponses,
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
          roles: AdminSupervisorRoles,
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
          roles: AdminSupervisorRoles,
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
          roles: AdminSupervisorRoles,
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
          roles: AdminSupervisorRoles,
          component: TeamReports,
        },
      ],
    },
  ],
};
