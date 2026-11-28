import { API } from 'widget/helpers/axios';
import { sendMessage } from 'widget/helpers/utils';
import { actions } from '../../contacts';

const commit = vi.fn();
const dispatch = vi.fn();

vi.mock('widget/helpers/axios');
vi.mock('widget/helpers/utils', () => ({
  sendMessage: vi.fn(),
}));

describe('#actions', () => {
  describe('#setUser', () => {
    it('sends correct actions if contact object is refreshed ', async () => {
      const user = {
        email: 'thoma@sphadikam.com',
        name: 'Adu Thoma',
        avatar_url: '',
      };
      vi.spyOn(API, 'patch').mockResolvedValue({
        data: { widget_auth_token: 'token' },
      });
      await actions.setUser(
        { commit, dispatch },
        { identifier: 1, user, userHash: 'user-hash' }
      );
      expect(sendMessage.mock.calls).toEqual([
        [{ data: { widgetAuthToken: 'token' }, event: 'setAuthCookie' }],
        [{ data: { userHash: 'user-hash' }, event: 'setUserCookie' }],
      ]);
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([
        ['get'],
        ['conversation/clearConversations', {}, { root: true }],
        ['conversation/fetchOldConversations', {}, { root: true }],
        ['conversationAttributes/getAttributes', {}, { root: true }],
      ]);
    });

    it('sends correct actions if identifierHash is passed ', async () => {
      const user = {
        email: 'thoma@sphadikam.com',
        name: 'Adu Thoma',
        avatar_url: '',
        identifier_hash: '12345',
      };
      vi.spyOn(API, 'patch').mockResolvedValue({ data: { id: 1 } });
      await actions.setUser(
        { commit, dispatch },
        { identifier: 1, user, userHash: 'user-hash' }
      );
      expect(sendMessage.mock.calls).toEqual([
        [{ data: { userHash: 'user-hash' }, event: 'setUserCookie' }],
      ]);
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([
        ['get'],
        ['conversation/clearConversations', {}, { root: true }],
        ['conversation/fetchOldConversations', {}, { root: true }],
        ['conversationAttributes/getAttributes', {}, { root: true }],
      ]);
    });

    it('does not call sendMessage if contact object is not refreshed ', async () => {
      const user = {
        email: 'thoma@sphadikam.com',
        name: 'Adu Thoma',
        avatar_url: '',
      };
      API.patch.mockResolvedValue({ data: { id: 1 } });
      await actions.setUser(
        { commit, dispatch },
        { identifier: 1, user, userHash: 'user-hash' }
      );
      expect(sendMessage.mock.calls).toEqual([
        [{ data: { userHash: 'user-hash' }, event: 'setUserCookie' }],
      ]);
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([['get']]);
    });

    it('does not confirm the user when the request fails', async () => {
      const user = { email: 'thoma@sphadikam.com', name: 'Adu Thoma' };
      const error = { response: { data: { error: 'Invalid hash' } } };
      API.patch.mockRejectedValue(error);
      await actions.setUser(
        { commit, dispatch },
        { identifier: 1, user, userHash: 'user-hash' }
      );
      expect(sendMessage.mock.calls).toEqual([
        [
          {
            event: 'error',
            errorType: 'SET_USER_ERROR',
            data: { error: 'Invalid hash' },
          },
        ],
      ]);
      expect(dispatch.mock.calls).toEqual([]);
    });
  });

  describe('#update', () => {
    it('sends correct actions', async () => {
      const user = {
        email: 'thoma@sphadikam.com',
        name: 'Adu Thoma',
        avatar_url: '',
        identifier_hash: 'random_hex_identifier_hash',
      };
      API.patch.mockResolvedValue({ data: { id: 1 } });
      await actions.update({ commit, dispatch }, { identifier: 1, user });
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([['get']]);
    });
  });
});
