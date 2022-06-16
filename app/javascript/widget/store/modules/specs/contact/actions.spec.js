import { API } from 'widget/helpers/axios';
import { actions } from '../../contacts';

const commit = jest.fn();
const dispatch = jest.fn();
jest.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#update', () => {
    it('sends correct actions', async () => {
      const user = {
        email: 'thoma@sphadikam.com',
        name: 'Adu Thoma',
        avatar_url: '',
        identifier_hash: 'random_hex_identifier_hash',
      };
      API.patch.mockResolvedValue({ data: { pubsub_token: 'token' } });
      await actions.update({ commit, dispatch }, { identifier: 1, user });
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([
        ['get'],
        ['conversation/clearConversations', {}, { root: true }],
        ['conversation/fetchOldConversations', {}, { root: true }],
        ['conversationAttributes/getAttributes', {}, { root: true }],
      ]);
    });
  });
});
