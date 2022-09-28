import axios from 'axios';
import { actions } from '../../contactConversations';
import * as types from '../../../mutation-types';
import conversationList from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: conversationList } });
      await actions.get({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isFetching: true }],

        [
          types.default.SET_CONTACT_CONVERSATIONS,
          { id: 1, data: conversationList },
        ],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isFetching: false },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isFetching: true }],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isFetching: false },
        ],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: conversationList[0] });
      await actions.create(
        { commit },
        {
          inboxId: 1,
          message: { content: 'hi' },
          contactId: 4,
          sourceId: 5,
          mailSubject: 'Mail Subject',
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],

        [
          types.default.ADD_CONTACT_CONVERSATION,
          { id: 4, data: conversationList[0] },
        ],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });

      await expect(
        actions.create(
          { commit },
          {
            inboxId: 1,
            message: { content: 'hi' },
            contactId: 4,
            sourceId: 5,
            mailSubject: 'Mail Subject',
          }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
  });
});
