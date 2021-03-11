/**
 * @jest-environment jsdom
 */

import { shouldPlayAudio } from '../AudioNotificationHelper';

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
