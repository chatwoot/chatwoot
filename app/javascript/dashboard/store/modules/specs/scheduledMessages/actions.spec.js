import { actions } from '../../scheduledMessages';
import * as types from '../../../mutation-types';
import ScheduledMessagesAPI from '../../../../api/scheduledMessages';

describe('#scheduledMessages actions', () => {
  describe('#get', () => {
    it('fetches and sets all scheduled messages for a conversation', async () => {
      const commit = vi.fn();
      vi.spyOn(ScheduledMessagesAPI, 'get').mockResolvedValue({
        data: {
          payload: [{ id: 1 }, { id: 2 }],
        },
      });

      await actions.get({ commit }, { conversationId: '12' });

      expect(commit).toHaveBeenCalledWith(
        types.default.SET_SCHEDULED_MESSAGES_UI_FLAG,
        { isFetching: true }
      );
      expect(commit).toHaveBeenCalledWith(
        types.default.SET_SCHEDULED_MESSAGES,
        { conversationId: 12, data: [{ id: 1 }, { id: 2 }] }
      );
      expect(commit).toHaveBeenCalledWith(
        types.default.SET_SCHEDULED_MESSAGES_UI_FLAG,
        { isFetching: false }
      );
    });
  });

  describe('#create', () => {
    it('commits ADD_SCHEDULED_MESSAGE and returns created data', async () => {
      const commit = vi.fn();
      vi.spyOn(ScheduledMessagesAPI, 'create').mockResolvedValue({
        data: { id: 9 },
      });

      const result = await actions.create(
        { commit },
        { conversationId: '7', payload: { content: 'Hello' } }
      );

      expect(result).toEqual({ id: 9 });
      expect(commit).toHaveBeenCalledWith(types.default.ADD_SCHEDULED_MESSAGE, {
        conversationId: 7,
        data: { id: 9 },
      });
    });
  });

  describe('#update', () => {
    it('commits UPDATE_SCHEDULED_MESSAGE and returns updated data', async () => {
      const commit = vi.fn();
      vi.spyOn(ScheduledMessagesAPI, 'update').mockResolvedValue({
        data: { id: 9, status: 'pending' },
      });

      const result = await actions.update(
        { commit },
        { conversationId: '7', scheduledMessageId: 3, payload: {} }
      );

      expect(result).toEqual({ id: 9, status: 'pending' });
      expect(commit).toHaveBeenCalledWith(
        types.default.UPDATE_SCHEDULED_MESSAGE,
        { conversationId: 7, data: { id: 9, status: 'pending' } }
      );
    });
  });

  describe('#delete', () => {
    it('commits DELETE_SCHEDULED_MESSAGE', async () => {
      const commit = vi.fn();
      vi.spyOn(ScheduledMessagesAPI, 'delete').mockResolvedValue({});

      await actions.delete(
        { commit },
        { conversationId: '7', scheduledMessageId: 3 }
      );

      expect(commit).toHaveBeenCalledWith(
        types.default.DELETE_SCHEDULED_MESSAGE,
        { conversationId: 7, scheduledMessageId: 3 }
      );
    });
  });

  describe('#upsertFromEvent', () => {
    it('updates if record exists, adds if new', () => {
      const commit = vi.fn();
      const state = { records: { 5: [{ id: 1 }] } };

      actions.upsertFromEvent(
        { commit, state },
        { id: 1, conversation_id: '5' }
      );

      expect(commit).toHaveBeenCalledWith(
        types.default.UPDATE_SCHEDULED_MESSAGE,
        expect.objectContaining({ conversationId: 5 })
      );

      commit.mockClear();

      actions.upsertFromEvent(
        { commit, state },
        { id: 2, conversation_id: '5' }
      );

      expect(commit).toHaveBeenCalledWith(
        types.default.ADD_SCHEDULED_MESSAGE,
        expect.objectContaining({ conversationId: 5 })
      );
    });
  });

  describe('#removeFromEvent', () => {
    it('commits DELETE_SCHEDULED_MESSAGE from event payload', () => {
      const commit = vi.fn();

      actions.removeFromEvent({ commit }, { id: 3, conversation_id: '8' });

      expect(commit).toHaveBeenCalledWith(
        types.default.DELETE_SCHEDULED_MESSAGE,
        { conversationId: 8, scheduledMessageId: 3 }
      );
    });
  });
});
