import { describe, it, beforeEach, expect, vi } from 'vitest';
import ActionCableConnector from '../actionCable';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

vi.mock('dashboard/composables/useImpersonation', () => ({
  useImpersonation: () => ({
    isImpersonating: { value: false },
  }),
}));

global.chatwootConfig = {
  websocketURL: 'wss://test.chatwoot.com',
};

describe('ActionCableConnector - Copilot Tests', () => {
  let store;
  let actionCable;
  let mockDispatch;

  beforeEach(() => {
    vi.clearAllMocks();
    mockDispatch = vi.fn();
    store = {
      $store: {
        dispatch: mockDispatch,
        getters: {
          getCurrentAccountId: 1,
        },
      },
    };

    actionCable = ActionCableConnector.init(store.$store, 'test-token');
  });
  describe('contact.group_synced event handler', () => {
    it('should register the contact.group_synced event handler', () => {
      expect(Object.keys(actionCable.events)).toContain('contact.group_synced');
      expect(actionCable.events['contact.group_synced']).toBe(
        actionCable.onContactGroupSynced
      );
    });

    it('should dispatch groupMembers/setGroupMembers with contact id and members from payload', () => {
      const groupSyncedData = {
        id: 42,
        name: 'Test Group',
        account_id: 1,
        group_members: [
          {
            id: 1,
            role: 'admin',
            is_active: true,
            contact: {
              id: 10,
              name: 'Alice',
              phone_number: '+1234567890',
              thumbnail: null,
            },
          },
          {
            id: 2,
            role: 'member',
            is_active: true,
            contact: {
              id: 11,
              name: 'Bob',
              phone_number: '+0987654321',
              thumbnail: null,
            },
          },
        ],
      };

      actionCable.onReceived({
        event: 'contact.group_synced',
        data: groupSyncedData,
      });

      expect(mockDispatch).toHaveBeenCalledWith(
        'groupMembers/setGroupMembers',
        {
          contactId: 42,
          members: groupSyncedData.group_members,
        }
      );
    });
  });

  describe('copilot event handlers', () => {
    it('should register the copilot.message.created event handler', () => {
      expect(Object.keys(actionCable.events)).toContain(
        'copilot.message.created'
      );
      expect(actionCable.events['copilot.message.created']).toBe(
        actionCable.onCopilotMessageCreated
      );
    });

    it('should handle the copilot.message.created event through the ActionCable system', () => {
      const copilotData = {
        id: 2,
        content: 'This is a copilot message from ActionCable',
        conversation_id: 456,
        created_at: '2025-05-27T15:58:04-06:00',
        account_id: 1,
      };
      actionCable.onReceived({
        event: 'copilot.message.created',
        data: copilotData,
      });
      expect(mockDispatch).toHaveBeenCalledWith(
        'copilotMessages/upsert',
        copilotData
      );
    });
  });
});
