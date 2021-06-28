/**
 * @jest-environment jsdom
 */

import {
  shouldPlayByBrowserBehavior,
  shouldPlayByUserSettings,
  getAssigneeFromNotification,
} from '../AudioNotificationHelper';

describe('shouldPlayByBrowserBehavior', () => {
  describe('Document active', () => {
    it('Retuns true if incoming message', () => {
      const message = {
        conversation_id: 10,
        sender_id: 5,
        message_type: 0,
        private: false,
      };
      const [conversationId, userId, isDocHiddden] = [1, 2, false];
      const result = shouldPlayByBrowserBehavior(
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
      const result = shouldPlayByBrowserBehavior(
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
      const result = shouldPlayByBrowserBehavior(
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
      const result = shouldPlayByBrowserBehavior(
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
      const result = shouldPlayByBrowserBehavior(
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
      const result = shouldPlayByBrowserBehavior(
        message,
        conversationId,
        userId,
        isDocHiddden
      );
      expect(result).toBe(false);
    });
  });
});
describe('shouldPlayByUserSettings', () => {
  it('Retuns true if mine', () => {
    const [enableAudioAlerts, userId, id] = ['mine', 1, 1];
    const result = shouldPlayByUserSettings(enableAudioAlerts, userId, id);
    expect(result).toBe(true);
  });
  it('Retuns true if all', () => {
    const [enableAudioAlerts, userId, id] = ['all', 1, 2];
    const result = shouldPlayByUserSettings(enableAudioAlerts, userId, id);
    expect(result).toBe(true);
  });
  it('Retuns false if none', () => {
    const [enableAudioAlerts, userId, id] = ['none', 1, 2];
    const result = shouldPlayByUserSettings(enableAudioAlerts, userId, id);
    expect(result).toBe(false);
  });
});
describe('getAssigneeFromNotification', () => {
  it('Retuns true if gets notification from assignee', () => {
    const currentConv = {};
    const result = getAssigneeFromNotification(currentConv);
    expect(result).toBe(undefined);
  });
});
