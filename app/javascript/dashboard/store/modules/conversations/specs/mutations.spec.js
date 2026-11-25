import { mutations } from '../index';
import types from '../../../mutation-types';

describe('#mutations', () => {
  describe('#REMOVE_CONVERSATIONS', () => {
    it('removes only the ids it was given', () => {
      const state = { allConversations: [{ id: 1 }, { id: 2 }, { id: 3 }] };
      mutations[types.REMOVE_CONVERSATIONS](state, [1, 3]);
      expect(state.allConversations).toEqual([{ id: 2 }]);
    });

    it('leaves the list untouched when nothing matches', () => {
      const state = { allConversations: [{ id: 1 }, { id: 2 }] };
      mutations[types.REMOVE_CONVERSATIONS](state, [99]);
      expect(state.allConversations).toEqual([{ id: 1 }, { id: 2 }]);
    });
  });

  describe('#UPDATE_MESSAGE_CALL_STATUS', () => {
    it('does nothing if conversation is not found', () => {
      const state = { allConversations: [] };
      mutations[types.UPDATE_MESSAGE_CALL_STATUS](state, {
        conversationId: 1,
        callStatus: 'ringing',
        callSid: 'CA123',
      });
      expect(state.allConversations).toEqual([]);
    });

    it('does nothing if no matching voice call message exists', () => {
      const state = {
        allConversations: [
          { id: 1, messages: [{ id: 1, content_type: 'text' }] },
        ],
      };
      mutations[types.UPDATE_MESSAGE_CALL_STATUS](state, {
        conversationId: 1,
        callStatus: 'ringing',
        callSid: 'CA123',
      });
      expect(state.allConversations[0].messages[0]).toEqual({
        id: 1,
        content_type: 'text',
      });
    });

    it('updates only the voice call message matching the given callSid', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                id: 1,
                content_type: 'voice_call',
                call: { provider_call_id: 'CA111', status: 'ringing' },
              },
              {
                id: 2,
                content_type: 'voice_call',
                call: { provider_call_id: 'CA222', status: 'ringing' },
              },
            ],
          },
        ],
      };
      mutations[types.UPDATE_MESSAGE_CALL_STATUS](state, {
        conversationId: 1,
        callStatus: 'in-progress',
        callSid: 'CA111',
      });
      expect(state.allConversations[0].messages[0].call.status).toBe(
        'in-progress'
      );
      expect(state.allConversations[0].messages[1].call.status).toBe('ringing');
    });

    it('preserves existing call fields when updating status', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                id: 1,
                content_type: 'voice_call',
                call: {
                  provider_call_id: 'CA123',
                  status: 'ringing',
                  direction: 'incoming',
                  duration_seconds: null,
                },
              },
            ],
          },
        ],
      };
      mutations[types.UPDATE_MESSAGE_CALL_STATUS](state, {
        conversationId: 1,
        callStatus: 'in-progress',
        callSid: 'CA123',
      });
      expect(state.allConversations[0].messages[0].call).toEqual({
        provider_call_id: 'CA123',
        status: 'in-progress',
        direction: 'incoming',
        duration_seconds: null,
      });
    });

    it('handles empty messages array', () => {
      const state = {
        allConversations: [{ id: 1, messages: [] }],
      };
      mutations[types.UPDATE_MESSAGE_CALL_STATUS](state, {
        conversationId: 1,
        callStatus: 'ringing',
        callSid: 'CA123',
      });
      expect(state.allConversations[0].messages).toEqual([]);
    });

    it('does nothing if matching message has no call object yet', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                id: 1,
                content_type: 'voice_call',
                call: { provider_call_id: 'CA-OTHER' },
              },
            ],
          },
        ],
      };
      mutations[types.UPDATE_MESSAGE_CALL_STATUS](state, {
        conversationId: 1,
        callStatus: 'completed',
        callSid: 'CA-MISSING',
      });
      expect(state.allConversations[0].messages[0].call).toEqual({
        provider_call_id: 'CA-OTHER',
      });
    });
  });
});
