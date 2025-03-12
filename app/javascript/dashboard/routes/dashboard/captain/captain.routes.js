import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';
import AssistantIndex from './assistants/Index.vue';
import AssistantInboxesIndex from './assistants/inboxes/Index.vue';
import DocumentsIndex from './documents/Index.vue';
import ResponsesIndex from './responses/Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/captain/assistants'),
    component: AssistantIndex,
    name: 'captain_assistants_index',
    meta: {
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/assistants/:assistantId/inboxes'
    ),
    component: AssistantInboxesIndex,
    name: 'captain_assistants_inboxes_index',
    meta: {
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/documents'),
    component: DocumentsIndex,
    name: 'captain_documents_index',
    meta: {
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      permissions: ['administrator', 'agent'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/responses'),
    component: ResponsesIndex,
    name: 'captain_responses_index',
    meta: {
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      permissions: ['administrator', 'agent'],
    },
  },
];
