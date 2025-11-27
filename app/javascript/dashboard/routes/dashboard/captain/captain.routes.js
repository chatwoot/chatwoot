import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../helper/URLHelper';

import CaptainPageRouteView from './pages/CaptainPageRouteView.vue';
import AssistantsIndexPage from './pages/AssistantsIndexPage.vue';
import AssistantEmptyStateIndex from './assistants/Index.vue';

import AssistantSettingsIndex from './assistants/settings/Settings.vue';
import AssistantInboxesIndex from './assistants/inboxes/Index.vue';
import AssistantPlaygroundIndex from './assistants/playground/Index.vue';
import AssistantGuardrailsIndex from './assistants/guardrails/Index.vue';
import AssistantGuidelinesIndex from './assistants/guidelines/Index.vue';
import AssistantScenariosIndex from './assistants/scenarios/Index.vue';
import DocumentsIndex from './documents/Index.vue';
import ResponsesIndex from './responses/Index.vue';
import ResponsesPendingIndex from './responses/Pending.vue';
import CustomToolsIndex from './tools/Index.vue';

const meta = {
  permissions: ['administrator', 'agent'],
  featureFlag: FEATURE_FLAGS.CAPTAIN,
  installationTypes: [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE],
};

const metaV2 = {
  permissions: ['administrator', 'agent'],
  featureFlag: FEATURE_FLAGS.CAPTAIN_V2,
  installationTypes: [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE],
};

const assistantRoutes = [
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/faqs'),
    component: ResponsesIndex,
    name: 'captain_assistants_responses_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/documents'),
    component: DocumentsIndex,
    name: 'captain_assistants_documents_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/tools'),
    component: CustomToolsIndex,
    name: 'captain_tools_index',
    meta: metaV2,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/scenarios'),
    component: AssistantScenariosIndex,
    name: 'captain_assistants_scenarios_index',
    meta: metaV2,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/playground'),
    component: AssistantPlaygroundIndex,
    name: 'captain_assistants_playground_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/inboxes'),
    component: AssistantInboxesIndex,
    name: 'captain_assistants_inboxes_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/faqs/pending'),
    component: ResponsesPendingIndex,
    name: 'captain_assistants_responses_pending',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/settings'),
    component: AssistantSettingsIndex,
    name: 'captain_assistants_settings_index',
    meta,
  },
  // Settings sub-pages (guardrails and guidelines)
  {
    path: frontendURL(
      'accounts/:accountId/captain/:assistantId/settings/guardrails'
    ),
    component: AssistantGuardrailsIndex,
    name: 'captain_assistants_guardrails_index',
    meta: metaV2,
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/:assistantId/settings/guidelines'
    ),
    component: AssistantGuidelinesIndex,
    name: 'captain_assistants_guidelines_index',
    meta: metaV2,
  },
  {
    path: frontendURL('accounts/:accountId/captain/assistants'),
    component: AssistantEmptyStateIndex,
    name: 'captain_assistants_create_index',
    meta: {
      permissions: ['administrator', 'agent'],
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/:navigationPath'),
    component: AssistantsIndexPage,
    name: 'captain_assistants_index',
    meta,
  },
];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/captain'),
    component: CaptainPageRouteView,
    redirect: to => {
      return {
        name: 'captain_assistants_index',
        params: {
          navigationPath: 'captain_assistants_responses_index',
          ...to.params,
        },
      };
    },
    children: [...assistantRoutes],
  },
];
