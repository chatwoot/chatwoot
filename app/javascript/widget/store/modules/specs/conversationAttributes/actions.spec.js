import { actions } from '../../conversationAttributes';
import { API } from 'widget/helpers/axios';

const commit = jest.fn();
jest.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#update', () => {
    it('sends mutation if api is success', async () => {
      API.get.mockResolvedValue({ data: { id: 1, status: 'bot' } });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        ['SET_CONVERSATION_ATTRIBUTES', { id: 1, status: 'bot' }],
        ['conversation/setMetaUserLastSeenAt', undefined, { root: true }],
      ]);
    });
    it('doesnot send mutation if api is error', async () => {
      API.get.mockRejectedValue({ message: 'Invalid Headers' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#update', () => {
    it('sends correct mutations', () => {
      actions.update({ commit }, { id: 1, status: 'bot' });
      expect(commit).toBeCalledWith('UPDATE_CONVERSATION_ATTRIBUTES', {
        id: 1,
        status: 'bot',
      });
    });
  });
});
