import axios from 'axios';
import { actions } from '../../conversationUnreadCounts';
import types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    commit.mockClear();
    axios.get.mockReset();
  });

  describe('#get', () => {
    it('commits unread counts when API is successful', async () => {
      const payload = {
        inboxes: { 1: '2' },
        labels: { 3: 4 },
      };
      axios.get.mockResolvedValue({ data: { payload } });

      await actions.get({ commit });

      expect(axios.get).toHaveBeenCalledWith(
        '/api/v1/conversations/unread_counts'
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_UNREAD_COUNTS, payload],
      ]);
    });

    it('does not commit when API fails', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });

      await actions.get({ commit });

      expect(commit).not.toHaveBeenCalled();
    });
  });
});
