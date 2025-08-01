import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../helper/URLHelper';
import AssistantIndex from './assistants/Index.vue';
import AssistantInboxesIndex from './assistants/inboxes/Index.vue';
import DocumentsIndex from './documents/Index.vue';
import ToolsIndex from './tools/Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/aiagent/assistants'),
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
    path: frontendURL(
      'accounts/:accountId/aiagent/assistants/:assistantId/inboxes'
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
    path: frontendURL('accounts/:accountId/aiagent/documents'),
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
    path: frontendURL('accounts/:accountId/aiagent/tools'),
    component: ToolsIndex,
    name: 'captain_tools_index',
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
