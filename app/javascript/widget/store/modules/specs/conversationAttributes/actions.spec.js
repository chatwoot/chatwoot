import { API } from 'widget/helpers/axios';
import { actions } from '../../conversationAttributes';

const commit = vi.fn();
vi.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#get attributes', () => {
    it('sends mutation if api is success', async () => {
      API.get.mockResolvedValue({ data: { id: 1, status: 'pending' } });
      await actions.getAttributes({ commit, state: { id: '' } });
      expect(commit.mock.calls).toEqual([
        ['SET_CONVERSATION_ATTRIBUTES', { id: 1, status: 'pending' }],
        ['conversation/setMetaUserLastSeenAt', undefined, { root: true }],
      ]);
    });
    it('ignores a response for another conversation when multiple conversations are enabled', async () => {
      window.chatwootWebChannel = {
        enabledFeatures: ['multiple_conversations'],
      };
      API.get.mockResolvedValue({ data: { id: 2, status: 'open' } });
      await actions.getAttributes({ commit, state: { id: 1 } });
      expect(commit.mock.calls).toEqual([]);
      delete window.chatwootWebChannel;
    });
    it('doesnot send mutation if api is error', async () => {
      API.get.mockRejectedValue({ message: 'Invalid Headers' });
      await actions.getAttributes({ commit, state: { id: '' } });
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#update attributes', () => {
    it('sends correct mutations', () => {
      actions.update({ commit }, { id: 1, status: 'pending' });
      expect(commit).toBeCalledWith('UPDATE_CONVERSATION_ATTRIBUTES', {
        id: 1,
        status: 'pending',
      });
    });
  });
  describe('#clear attributes', () => {
    it('sends correct mutations', () => {
      actions.clearConversationAttributes({ commit });
      expect(commit).toBeCalledWith('CLEAR_CONVERSATION_ATTRIBUTES');
    });
  });
});
