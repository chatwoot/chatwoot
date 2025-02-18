import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions';
import { getUserPermissions } from 'dashboard/helper/permissionsHelper';

class AudioNotificationStore {
  constructor(store) {
    this.store = store;
  }

  hasUnreadConversation = () => {
    const mineConversation = this.store.getters.getMineChats({
      assigneeType: 'me',
      status: 'open',
    });

    return mineConversation.some(conv => conv.unread_count > 0);
  };

  isMessageFromCurrentConversation = message => {
    return this.store.getters.getSelectedChat?.id === message.conversation_id;
  };

  hasConversationPermission = user => {
    const currentAccountId = this.store.getters.getCurrentAccountId;
    // Get the user permissions for the current account
    const userPermissions = getUserPermissions(user, currentAccountId);
    // Check if the user has the required permissions
    const hasRequiredPermission = [...ROLES, ...CONVERSATION_PERMISSIONS].some(
      permission => userPermissions.includes(permission)
    );
    return hasRequiredPermission;
  };
}

export default AudioNotificationStore;
