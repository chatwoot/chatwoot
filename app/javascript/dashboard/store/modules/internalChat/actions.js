import InternalChatChannelsAPI from '../../../api/internalChatChannels';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export const actions = {
  // Drops everything the module holds, for a member who just lost access to internal chat.
  reset({ commit }) {
    commit('RESET');
    commit('messages/RESET');
    commit('drafts/RESET');
    commit('search/RESET');
  },
  get: async ({ commit }) => {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const [channelsResponse, categoriesResponse] = await Promise.all([
        InternalChatChannelsAPI.get(),
        InternalChatChannelsAPI.getCategories(),
      ]);
      commit('SET_CHANNELS', channelsResponse.data);
      commit('SET_CATEGORIES', categoriesResponse.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  show: async ({ commit }, channelId) => {
    try {
      const response = await InternalChatChannelsAPI.show(channelId);
      commit('ADD_CHANNEL', response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  fetchArchived: async ({ commit }) => {
    commit('SET_UI_FLAG', { isFetchingArchived: true });
    try {
      const response = await InternalChatChannelsAPI.getWithParams({
        status: 'archived',
      });
      commit('SET_ARCHIVED_CHANNELS', response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetchingArchived: false });
    }
  },

  create: async ({ commit }, channelData) => {
    commit('SET_UI_FLAG', { isCreating: true });
    try {
      const response = await InternalChatChannelsAPI.create(channelData);
      commit('ADD_CHANNEL', response.data);
      return response.data;
    } catch (error) {
      if (error?.response?.status === 402) throw error;
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isCreating: false });
    }
  },

  update: async ({ commit, getters }, { channelId, ...data }) => {
    const previous = { ...getters.getChannelById(channelId) };
    commit('UPDATE_CHANNEL', { id: channelId, ...data.channel });
    try {
      const response = await InternalChatChannelsAPI.update(channelId, data);
      commit('UPDATE_CHANNEL', response.data);
      return response.data;
    } catch (error) {
      commit('UPDATE_CHANNEL', previous);
      throwErrorMessage(error);
      throw error;
    }
  },

  delete: async ({ commit }, channelId) => {
    try {
      await InternalChatChannelsAPI.delete(channelId);
      commit('DELETE_CHANNEL', channelId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  archive: async ({ commit }, channelId) => {
    try {
      const response = await InternalChatChannelsAPI.archive(channelId);
      commit('UPDATE_CHANNEL', response.data);
      commit('ADD_ARCHIVED_CHANNEL', response.data);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  unarchive: async ({ commit }, channelId) => {
    try {
      const response = await InternalChatChannelsAPI.unarchive(channelId);
      commit('ADD_CHANNEL', response.data);
      commit('REMOVE_ARCHIVED_CHANNEL', channelId);
    } catch (error) {
      if (error?.response?.status === 402) throw error;
      throwErrorMessage(error);
      throw error;
    }
  },

  toggleMute: async ({ commit, state, rootGetters }, channelId) => {
    const channel = state.records[channelId];
    if (!channel) return;
    const currentUserId = rootGetters.getCurrentUser?.id;
    const member = (channel.members || []).find(
      m => m.user_id === currentUserId
    );
    if (!member) return;

    const newMuted = !channel.muted;
    commit('UPDATE_CHANNEL', { id: channelId, muted: newMuted });
    try {
      await InternalChatChannelsAPI.updateMember(channelId, member.id, {
        muted: newMuted,
      });
    } catch (error) {
      commit('UPDATE_CHANNEL', { id: channelId, muted: !newMuted });
      throwErrorMessage(error);
    }
  },

  toggleFavorite: async ({ commit, state, rootGetters }, channelId) => {
    const channel = state.records[channelId];
    if (!channel) return;
    const currentUserId = rootGetters.getCurrentUser?.id;
    const member = (channel.members || []).find(
      m => m.user_id === currentUserId
    );
    if (!member) return;

    const newFavorited = !channel.favorited;
    commit('UPDATE_CHANNEL', { id: channelId, favorited: newFavorited });
    try {
      await InternalChatChannelsAPI.updateMember(channelId, member.id, {
        favorited: newFavorited,
      });
    } catch (error) {
      commit('UPDATE_CHANNEL', { id: channelId, favorited: !newFavorited });
      throwErrorMessage(error);
    }
  },

  markRead: async ({ commit }, channelId) => {
    try {
      await InternalChatChannelsAPI.markRead(channelId);
      commit('UPDATE_CHANNEL', {
        id: channelId,
        unread_count: 0,
        has_unread_mention: false,
      });
    } catch (error) {
      throwErrorMessage(error);
    }
  },

  markUnread: async ({ commit }, { channelId, messageId }) => {
    try {
      await InternalChatChannelsAPI.markUnread(channelId, messageId);
      commit('UPDATE_CHANNEL', { id: channelId, unread_count: 1 });
    } catch (error) {
      throwErrorMessage(error);
    }
  },

  createCategory: async ({ commit }, categoryData) => {
    try {
      const response =
        await InternalChatChannelsAPI.createCategory(categoryData);
      commit('ADD_CATEGORY', response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  deleteCategory: async ({ commit, state }, categoryId) => {
    try {
      await InternalChatChannelsAPI.deleteCategory(categoryId);
      commit('REMOVE_CATEGORY', categoryId);
      // Move channels from deleted category to uncategorized
      Object.values(state.records).forEach(channel => {
        if (channel.category_id === categoryId) {
          commit('UPDATE_CHANNEL', { id: channel.id, category_id: null });
        }
      });
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  setActiveChannel: ({ commit }, channelId) => {
    commit('SET_ACTIVE_CHANNEL', channelId);
  },

  addChannel: ({ commit }, channel) => {
    commit('ADD_CHANNEL', channel);
  },

  updateChannel: ({ commit }, channel) => {
    commit('UPDATE_CHANNEL', channel);
  },
};

export default actions;
