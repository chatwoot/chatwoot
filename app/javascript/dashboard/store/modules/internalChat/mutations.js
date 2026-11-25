import { initialState } from './state';

export const mutations = {
  RESET(_state) {
    Object.assign(_state, initialState());
  },
  SET_CHANNELS(_state, channels) {
    const records = {};
    // Preserve archived channels already loaded (e.g. via show)
    Object.values(_state.records).forEach(existing => {
      if (existing.status === 'archived') {
        records[existing.id] = existing;
      }
    });
    channels.forEach(channel => {
      records[channel.id] = channel;
    });
    _state.records = records;
  },

  ADD_CHANNEL(_state, channel) {
    _state.records = {
      ..._state.records,
      [channel.id]: channel,
    };
  },

  UPDATE_CHANNEL(_state, channel) {
    const existing = _state.records[channel.id];
    if (existing) {
      _state.records = {
        ..._state.records,
        [channel.id]: { ...existing, ...channel },
      };
    }
  },

  DELETE_CHANNEL(_state, channelId) {
    const { [channelId]: _, ...rest } = _state.records;
    _state.records = rest;
    if (_state.activeChannelId === channelId) {
      _state.activeChannelId = null;
    }
  },

  SET_ARCHIVED_CHANNELS(_state, channels) {
    const records = {};
    channels.forEach(channel => {
      records[channel.id] = channel;
    });
    _state.archivedRecords = records;
  },

  ADD_ARCHIVED_CHANNEL(_state, channel) {
    _state.archivedRecords = {
      ..._state.archivedRecords,
      [channel.id]: channel,
    };
  },

  REMOVE_ARCHIVED_CHANNEL(_state, channelId) {
    const { [channelId]: _, ...rest } = _state.archivedRecords;
    _state.archivedRecords = rest;
  },

  SET_CATEGORIES(_state, categories) {
    _state.categories = categories;
  },

  ADD_CATEGORY(_state, category) {
    _state.categories = [...(_state.categories || []), category];
  },

  REMOVE_CATEGORY(_state, categoryId) {
    _state.categories = (_state.categories || []).filter(
      c => c.id !== categoryId
    );
  },

  SET_UI_FLAG(_state, flags) {
    _state.uiFlags = { ..._state.uiFlags, ...flags };
  },

  SET_ACTIVE_CHANNEL(_state, channelId) {
    _state.activeChannelId = channelId;
  },
};

export default mutations;
