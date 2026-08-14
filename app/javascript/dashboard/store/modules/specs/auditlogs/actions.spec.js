import axios from 'axios';
import { actions } from '../../auditlogs';
import * as types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#fetch', () => {
    it('passes filters through to the API and commits results', async () => {
      const logs = [{ id: 1, auditable_type: 'Inbox' }];
      axios.get.mockResolvedValue({
        data: {
          audit_logs: logs,
          total_entries: 1,
          per_page: 25,
          current_page: 2,
        },
      });
      await actions.fetch(
        { commit },
        { page: 2, q: 'jane', types: ['Inbox'], sort: 'asc' }
      );
      expect(axios.get.mock.calls[0][1]).toEqual({
        params: { page: 2, q: 'jane', types: ['Inbox'], sort: 'asc' },
      });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: true }],
        [types.default.SET_AUDIT_LOGS, logs],
        [
          types.default.SET_AUDIT_LOGS_META,
          { totalEntries: 1, perPage: 25, currentPage: 2 },
        ],
        [types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: false }],
      ]);
    });

    it('resets the fetching flag on API error', async () => {
      axios.get.mockRejectedValue({ message: 'Request failed' });
      await expect(actions.fetch({ commit }, {})).rejects.toThrow();
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: true }],
        [types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: false }],
      ]);
    });
  });
});
