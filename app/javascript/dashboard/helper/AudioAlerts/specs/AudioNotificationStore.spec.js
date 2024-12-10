import AudioNotificationStore from '../AudioNotificationStore';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions';
import { getUserPermissions } from 'dashboard/helper/permissionsHelper';
vi.mock('dashboard/helper/permissionsHelper', () => ({
  getUserPermissions: vi.fn(),
}));

describe('AudioNotificationStore', () => {
  let store;
  let audioNotificationStore;

  beforeEach(() => {
    store = {
      getters: {
        getMineChats: vi.fn(),
        getSelectedChat: null,
        getCurrentAccountId: 1,
      },
    };
    audioNotificationStore = new AudioNotificationStore(store);
  });

  describe('hasUnreadConversation', () => {
    it('should return true when there are unread conversations', () => {
      store.getters.getMineChats.mockReturnValue([
        { id: 1, unread_count: 2 },
        { id: 2, unread_count: 0 },
      ]);

      expect(audioNotificationStore.hasUnreadConversation()).toBe(true);
    });

    it('should return false when there are no unread conversations', () => {
      store.getters.getMineChats.mockReturnValue([
        { id: 1, unread_count: 0 },
        { id: 2, unread_count: 0 },
      ]);

      expect(audioNotificationStore.hasUnreadConversation()).toBe(false);
    });

    it('should return false when there are no conversations', () => {
      store.getters.getMineChats.mockReturnValue([]);

      expect(audioNotificationStore.hasUnreadConversation()).toBe(false);
    });

    it('should call getMineChats with correct parameters', () => {
      store.getters.getMineChats.mockReturnValue([]);
      audioNotificationStore.hasUnreadConversation();

      expect(store.getters.getMineChats).toHaveBeenCalledWith({
        assigneeType: 'me',
        status: 'open',
      });
    });
  });

  describe('isMessageFromCurrentConversation', () => {
    it('should return true when message is from selected chat', () => {
      store.getters.getSelectedChat = { id: 6179 };
      const message = { conversation_id: 6179 };

      expect(
        audioNotificationStore.isMessageFromCurrentConversation(message)
      ).toBe(true);
    });

    it('should return false when message is from different chat', () => {
      store.getters.getSelectedChat = { id: 6179 };
      const message = { conversation_id: 1337 };

      expect(
        audioNotificationStore.isMessageFromCurrentConversation(message)
      ).toBe(false);
    });

    it('should return false when no chat is selected', () => {
      store.getters.getSelectedChat = null;
      const message = { conversation_id: 6179 };

      expect(
        audioNotificationStore.isMessageFromCurrentConversation(message)
      ).toBe(false);
    });
  });

  describe('hasConversationPermission', () => {
    const mockUser = { id: 'user123' };

    beforeEach(() => {
      getUserPermissions.mockReset();
    });

    it('should return true when user has a required role', () => {
      getUserPermissions.mockReturnValue([ROLES[0]]);

      expect(audioNotificationStore.hasConversationPermission(mockUser)).toBe(
        true
      );
      expect(getUserPermissions).toHaveBeenCalledWith(mockUser, 1);
    });

    it('should return true when user has a conversation permission', () => {
      getUserPermissions.mockReturnValue([CONVERSATION_PERMISSIONS[0]]);

      expect(audioNotificationStore.hasConversationPermission(mockUser)).toBe(
        true
      );
    });

    it('should return false when user has no required permissions', () => {
      getUserPermissions.mockReturnValue(['some-other-permission']);

      expect(audioNotificationStore.hasConversationPermission(mockUser)).toBe(
        false
      );
    });

    it('should return false when user has no permissions', () => {
      getUserPermissions.mockReturnValue([]);

      expect(audioNotificationStore.hasConversationPermission(mockUser)).toBe(
        false
      );
    });
  });
});
