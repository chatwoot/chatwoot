import { frontendURL } from 'dashboard/helper/URLHelper.js';
import store from 'dashboard/store';

// Lazy-loaded pages (owned by HUB / CONSTRUTOR / PAINEL implementers).
// Dynamic imports keep this NAV module self-contained and code-split the
// Autonomia bundle out of the main dashboard chunk.
const AgentsHubPage = () => import('./pages/AgentsHubPage.vue');
const AgentBuilderPage = () => import('./pages/AgentBuilderPage.vue');
const AgentPanelPage = () => import('./pages/AgentPanelPage.vue');
const ProspectingSearchPage = () =>
  import('./prospecting/pages/ProspectingSearchPage.vue');
const ProspectingListsPage = () =>
  import('./prospecting/pages/ProspectingListsPage.vue');
const ProspectingSettingsPage = () =>
  import('./prospecting/pages/ProspectingSettingsPage.vue');
const InviteConnectionPage = () => import('./pages/InviteConnectionPage.vue');

// Admin-only: every Autonomia backend endpoint enforces
// `ensure_account_administrator`, so non-admins would 403 on each call.
const meta = {
  permissions: ['administrator'],
};

// Gate POR CONTA (aditivo, ISOLADO): mantém o ENV master (kill-switch global,
// exposto como window.globalConfig.AUTONOMIA_AGENTS_ENABLED) como pré-condição E
// exige a conta marcada como habilitada pelo gate isolado, exposto no payload da
// conta via `autonomia_agents_enabled` (_account.json.jbuilder ->
// Autonomia::Agents::Config.enabled?). NÃO depende do sistema de features do
// Chatwoot. Com a conta OFF, a rota redireciona para 'home' (recurso invisível,
// igual ao 404 do backend). Sem regressão: ENV OFF segue bloqueando todas as contas.
const ensureAutonomiaEnabled = (to, _from, next) => {
  const masterEnabled =
    window.globalConfig?.AUTONOMIA_AGENTS_ENABLED === 'true';
  const accountId = Number(to.params.accountId);
  const account = store.getters['accounts/getAccount'](accountId);
  const accountEnabled = account?.autonomia_agents_enabled === true;

  if (masterEnabled && accountEnabled) {
    next();
    return;
  }
  next({ name: 'home', params: to.params });
};

const ensureProspectingEnabled = (to, _from, next) => {
  const accountId = Number(to.params.accountId);
  const account = store.getters['accounts/getAccount'](accountId);

  if (account?.autonomia_prospecting_enabled === true) {
    next();
    return;
  }
  next({ name: 'home', params: to.params });
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/autonomia/invite-connection'),
    name: 'autonomia_invite_connection',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: InviteConnectionPage,
  },
  {
    path: frontendURL('accounts/:accountId/agents'),
    name: 'autonomia_agents_index',
    meta,
    beforeEnter: ensureAutonomiaEnabled,
    component: AgentsHubPage,
  },
  {
    path: frontendURL('accounts/:accountId/agents/new'),
    name: 'autonomia_agents_builder',
    meta,
    beforeEnter: ensureAutonomiaEnabled,
    component: AgentBuilderPage,
  },
  {
    path: frontendURL(
      'accounts/:accountId/agents/:agentId/:tab(test|knowledge|channels|performance|tune)?'
    ),
    name: 'autonomia_agent_panel',
    meta,
    beforeEnter: ensureAutonomiaEnabled,
    component: AgentPanelPage,
    props: route => ({
      agentId: route.params.agentId,
      tab: route.params.tab || 'test',
    }),
  },
  {
    path: frontendURL('accounts/:accountId/autonomia/prospecting/search'),
    name: 'autonomia_prospecting_search',
    meta,
    beforeEnter: ensureProspectingEnabled,
    component: ProspectingSearchPage,
  },
  {
    path: frontendURL('accounts/:accountId/autonomia/prospecting/lists'),
    name: 'autonomia_prospecting_lists',
    meta,
    beforeEnter: ensureProspectingEnabled,
    component: ProspectingListsPage,
  },
  {
    path: frontendURL('accounts/:accountId/autonomia/prospecting/settings'),
    name: 'autonomia_prospecting_settings',
    meta,
    beforeEnter: ensureProspectingEnabled,
    component: ProspectingSettingsPage,
  },
];

export default { routes };
