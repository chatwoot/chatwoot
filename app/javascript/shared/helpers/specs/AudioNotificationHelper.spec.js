/**
 * @jest-environment jsdom
 */

import {
  shouldPlayAudio,
  notificationEnabled,
  getAssigneeFromNotification,
} from '../AudioNotificationHelper';

describe('shouldPlayAudio', () => {
  describe('Document active', () => {
    it('Retuns true if incoming message', () => {
      const message = {
        conversation_id: 10,
        sender_id: 5,
        message_type: 0,
        private: false,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, false];
      const result = shouldPlayAudio(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(true);
    });
    it('Retuns false if outgoing message', () => {
      const message = {
        conversation_id: 10,
        sender_id: 5,
        message_type: 1,
        private: false,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, false];
      const result = shouldPlayAudio(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(false);
    });

    it('Retuns false if from Same sender', () => {
      const message = {
        conversation_id: 1,
        sender_id: 2,
        message_type: 0,
        private: false,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, true];
      const result = shouldPlayAudio(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(false);
    });
    it('Retuns true if private message from another agent', () => {
      const message = {
        conversation_id: 1,
        sender_id: 5,
        message_type: 1,
        private: true,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, true];
      const result = shouldPlayAudio(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(true);
    });
  });
  describe('Document inactive', () => {
    it('Retuns true if incoming message', () => {
      const message = {
        conversation_id: 1,
        sender_id: 5,
        message_type: 0,
        private: false,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, true];
      const result = shouldPlayAudio(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(true);
    });
    it('Retuns false if outgoing message', () => {
      const message = {
        conversation_id: 1,
        sender_id: 5,
        message_type: 1,
        private: false,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, true];
      const result = shouldPlayAudio(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(false);
    });
  });
});
describe('notificationEnabled', () => {
  it('returns true if mine', () => {
    const [enableAudioAlerts, userId, id] = ['mine', 1, 1];
    const result = notificationEnabled(enableAudioAlerts, userId, id);
    expect(result).toBe(true);
  });
  it('returns true if all', () => {
    const [enableAudioAlerts, userId, id] = ['all', 1, 2];
    const result = notificationEnabled(enableAudioAlerts, userId, id);
    expect(result).toBe(true);
  });
  it('returns false if none', () => {
    const [enableAudioAlerts, userId, id] = ['none', 1, 2];
    const result = notificationEnabled(enableAudioAlerts, userId, id);
    expect(result).toBe(false);
  });
});
describe('getAssigneeFromNotification', () => {
  it('Retuns true if gets notification from assignee', () => {
    const currentConv = {
      id: 1,
      accountId: 1,
      meta: {
        assignee: {
          id: 1,
          name: 'John',
        },
      },
    };
    const result = getAssigneeFromNotification(currentConv);
    expect(result).toBe(1);
  });
  it('Retuns true if gets notification from assignee is udefined', () => {
    const currentConv = {};
    const result = getAssigneeFromNotification(currentConv);
    expect(result).toBe(undefined);
  });
});
