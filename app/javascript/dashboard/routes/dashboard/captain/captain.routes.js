import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../helper/URLHelper';
import AssistantIndex from './assistants/Index.vue';
import AssistantEdit from './assistants/Edit.vue';
// import AssistantSettings from './assistants/settings/Settings.vue';
import AssistantInboxesIndex from './assistants/inboxes/Index.vue';
import AssistantGuardrailsIndex from './assistants/guardrails/Index.vue';
import AssistantGuidelinesIndex from './assistants/guidelines/Index.vue';
import AssistantScenariosIndex from './assistants/scenarios/Index.vue';
import DocumentsIndex from './documents/Index.vue';
import ResponsesIndex from './responses/Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/captain/assistants'),
    component: AssistantIndex,
    name: 'captain_assistants_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/assistants/:assistantId'),
    component: AssistantEdit,
    name: 'captain_assistants_edit',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/assistants/:assistantId/inboxes'
    ),
    component: AssistantInboxesIndex,
    name: 'captain_assistants_inboxes_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/assistants/:assistantId/guardrails'
    ),
    component: AssistantGuardrailsIndex,
    name: 'captain_assistants_guardrails_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/assistants/:assistantId/scenarios'
    ),
    component: AssistantScenariosIndex,
    name: 'captain_assistants_scenarios_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/assistants/:assistantId/guidelines'
    ),
    component: AssistantGuidelinesIndex,
    name: 'captain_assistants_guidelines_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/documents'),
    component: DocumentsIndex,
    name: 'captain_documents_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/responses'),
    component: ResponsesIndex,
    name: 'captain_responses_index',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];
