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

// Onboarding flow components
import AssistantCreateLoader from './assistants/create/Loader.vue';
import AssistantCreateSettings from './assistants/create/Settings.vue';
import AssistantCreateGuardrails from './assistants/create/Guardrails.vue';
import AssistantCreateScenarios from './assistants/create/Scenarios.vue';
import AssistantCreateGuidelines from './assistants/create/Guidelines.vue';

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
  // Assistant create onboarding flow routes
  {
    path: frontendURL('accounts/:accountId/captain/assistants/create'),
    component: AssistantCreateLoader,
    name: 'captain_assistants_create_loader',
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
    path: frontendURL('accounts/:accountId/captain/assistants/create/settings'),
    component: AssistantCreateSettings,
    name: 'captain_assistants_create_settings',
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
      'accounts/:accountId/captain/assistants/create/guardrails'
    ),
    component: AssistantCreateGuardrails,
    name: 'captain_assistants_create_guardrails',
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
      'accounts/:accountId/captain/assistants/create/scenarios'
    ),
    component: AssistantCreateScenarios,
    name: 'captain_assistants_create_scenarios',
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
      'accounts/:accountId/captain/assistants/create/guidelines'
    ),
    component: AssistantCreateGuidelines,
    name: 'captain_assistants_create_guidelines',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  // End
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
