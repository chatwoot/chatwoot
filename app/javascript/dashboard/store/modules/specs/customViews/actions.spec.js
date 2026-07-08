import axios from 'axios';
import * as types from '../../../mutation-types';
import { actions } from '../../customViews';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import {
  contactFilterView,
  customViewList,
  updateCustomViewList,
} from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

const mockRetryJitter = value =>
  vi.spyOn(Math, 'random').mockReturnValue(value);

const conversationUnreadCountsEnabledRootGetters = {
  getCurrentAccountId: 1,
  'accounts/isFeatureEnabledonAccount': vi.fn((_, featureFlag) =>
    [
      FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS,
      FEATURE_FLAGS.UNREAD_COUNT_FOR_FILTERS,
    ].includes(featureFlag)
  ),
};

afterEach(() => {
  vi.restoreAllMocks();
  vi.clearAllTimers();
  vi.useRealTimers();
});

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: customViewList });
      await actions.get({ commit }, 'conversation');
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: true }],
        [
          types.default.SET_CUSTOM_VIEW,
          { data: customViewList, filterType: 'conversation' },
        ],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      const firstItem = customViewList[0];
      axios.post.mockResolvedValue({ data: firstItem });
      await actions.create({ commit }, firstItem);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [
          types.default.ADD_CUSTOM_VIEW,
          { data: firstItem, filterType: 'conversation' },
        ],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });

    it('refetches unread counts after creating a conversation folder', async () => {
      vi.useFakeTimers();
      mockRetryJitter(0.5);
      const dispatch = vi.fn();
      const firstItem = customViewList[0];
      axios.post.mockResolvedValue({ data: firstItem });

      await actions.create(
        {
          commit,
          dispatch,
          rootGetters: conversationUnreadCountsEnabledRootGetters,
        },
        firstItem
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

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: customViewList[0] });
      await actions.delete({ commit }, { id: 1, filterType: 'contact' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_CUSTOM_VIEW, { data: 1, filterType: 'contact' }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: false }],
      ]);
    });

    it('refetches unread counts after deleting a conversation folder', async () => {
      vi.useFakeTimers();
      const dispatch = vi.fn();
      axios.delete.mockResolvedValue({ data: customViewList[0] });

      await actions.delete(
        {
          commit,
          dispatch,
          rootGetters: conversationUnreadCountsEnabledRootGetters,
        },
        { id: 1, filterType: 'conversation' }
      );

      expect(dispatch).toHaveBeenCalledWith(
        'conversationUnreadCounts/get',
        {},
        { root: true }
      );
    });

    it('does not refetch unread counts after deleting a contact segment', async () => {
      const dispatch = vi.fn();
      axios.delete.mockResolvedValue({ data: contactFilterView });

      await actions.delete(
        {
          commit,
          dispatch,
          rootGetters: conversationUnreadCountsEnabledRootGetters,
        },
        { id: 1, filterType: 'contact' }
      );

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit }, 1)).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      const item = updateCustomViewList[0];
      axios.patch.mockResolvedValue({ data: item });
      await actions.update({ commit }, item);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [
          types.default.UPDATE_CUSTOM_VIEW,
          { data: item, filterType: 'conversation' },
        ],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });

    it('refetches unread counts after updating a conversation folder', async () => {
      vi.useFakeTimers();
      const dispatch = vi.fn();
      const item = updateCustomViewList[0];
      axios.patch.mockResolvedValue({ data: item });

      await actions.update(
        {
          commit,
          dispatch,
          rootGetters: conversationUnreadCountsEnabledRootGetters,
        },
        item
      );

      expect(dispatch).toHaveBeenCalledWith(
        'conversationUnreadCounts/get',
        {},
        { root: true }
      );
    });

    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, 1)).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#setActiveConversationFolder', () => {
    it('set active conversation folder', async () => {
      await actions.setActiveConversationFolder({ commit }, customViewList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACTIVE_CONVERSATION_FOLDER, customViewList[0]],
      ]);
    });

    it('prefetches the contact of a contact filter', async () => {
      const dispatch = vi.fn();
      await actions.setActiveConversationFolder(
        { commit, dispatch },
        contactFilterView
      );
      expect(dispatch).toHaveBeenCalledWith(
        'contacts/show',
        { id: 42 },
        { root: true }
      );
    });

    it('does not prefetch without a contact filter', async () => {
      const dispatch = vi.fn();
      await actions.setActiveConversationFolder(
        { commit, dispatch },
        customViewList[0]
      );
      expect(dispatch).not.toHaveBeenCalled();
    });
  });
});
