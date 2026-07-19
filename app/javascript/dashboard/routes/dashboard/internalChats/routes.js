import { frontendURL } from '../../../helper/URLHelper';
import InternalChatsView from './InternalChatsView.vue';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from '../../../constants/permissions.js';
import { FEATURE_FLAGS } from '../../../featureFlags';

const chatPermissions = {
  permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  featureFlag: FEATURE_FLAGS.INTERNAL_CHATS,
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/internal-chats'),
    name: 'internal_chats_index',
    component: InternalChatsView,
    props: () => ({ conversationId: 0 }),
    meta: chatPermissions,
  },
  {
    path: frontendURL('accounts/:accountId/internal-chats/:conversationId'),
    name: 'internal_chats_show',
    component: InternalChatsView,
    props: route => ({ conversationId: route.params.conversationId }),
    meta: chatPermissions,
  },
];
