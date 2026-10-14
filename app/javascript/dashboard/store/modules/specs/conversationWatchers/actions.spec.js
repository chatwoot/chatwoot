import axios from 'axios';
import { actions } from '../../conversationWatchers';
import types from '../../../mutation-types';
import { FEATURE_FLAGS } from '../../../../featureFlags';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

const mockRetryJitter = value =>
  vi.spyOn(Math, 'random').mockReturnValue(value);

afterEach(() => {
  vi.restoreAllMocks();
  vi.clearAllTimers();
  vi.useRealTimers();
});

const conversationUnreadCountsEnabledRootGetters = {
  getCurrentAccountId: 1,
  getCurrentUserID: 1,
  'accounts/isFeatureEnabledonAccount': vi.fn((_, featureFlag) =>
    [
      FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS,
      FEATURE_FLAGS.UNREAD_COUNT_FOR_FILTERS,
    ].includes(featureFlag)
  ),
};

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { id: 1 } });
      await actions.show({ commit }, { conversationId: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: true }],
        [
          types.SET_CONVERSATION_PARTICIPANTS,
          { conversationId: 1, data: { id: 1 } },
        ],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.show({ commit }, { conversationId: 1 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: true }],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: [{ id: 2 }] });
      await actions.update(
        { commit },
        { conversationId: 2, userIds: [{ id: 2 }] }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: true }],
        [
          types.SET_CONVERSATION_PARTICIPANTS,
          { conversationId: 2, data: [{ id: 2 }] },
        ],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('refetches unread counts when the current user starts watching', async () => {
      vi.useFakeTimers();
      mockRetryJitter(0.5);
      const dispatch = vi.fn();
      const moduleState = { records: { 2: [] } };
      const mutatingCommit = vi.fn((mutation, payload) => {
        if (mutation === types.SET_CONVERSATION_PARTICIPANTS) {
          moduleState.records[payload.conversationId] = payload.data;
        }
      });
      axios.patch.mockResolvedValue({ data: [{ id: 1 }] });

      await actions.update(
        {
          commit: mutatingCommit,
          dispatch,
          rootGetters: conversationUnreadCountsEnabledRootGetters,
          state: moduleState,
        },
        { conversationId: 2, userIds: [1] }
      );

      expect(dispatch).toHaveBeenCalledWith(
        'conversationUnreadCounts/get',
        {},
        { root: true }
      );

      vi.advanceTimersByTime(37499);
      expect(dispatch).toHaveBeenCalledTimes(1);

      vi.advanceTimersByTime(1);
      expect(dispatch).toHaveBeenCalledTimes(2);
    });
    it('does not refetch unread counts when another watcher changes', async () => {
      const dispatch = vi.fn();
      axios.patch.mockResolvedValue({ data: [{ id: 1 }, { id: 2 }] });

      await actions.update(
        {
          commit,
          dispatch,
          rootGetters: conversationUnreadCountsEnabledRootGetters,
          state: { records: { 2: [{ id: 1 }] } },
        },
        { conversationId: 2, userIds: [1, 2] }
      );

      expect(dispatch).not.toHaveBeenCalled();
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, { conversationId: 1, content: 'hi' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: true }],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });
});
