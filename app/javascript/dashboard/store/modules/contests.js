import types from '../mutation-types';
import ContestsAPI from '../../api/contests';
import { throwErrorMessage } from '../utils/api';

const isDevEnv = typeof import.meta !== 'undefined' && import.meta.env?.DEV;
const logDebug = (...args) => {
  if (!isDevEnv) {
    return;
  }
  // eslint-disable-next-line no-console
  console.debug('[contests]', ...args);
};

const state = {
  records: [],
  hasLoaded: false,
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isCustomersFetching: false,
  },
};

const getters = {
  getRecords: _state => _state.records,
  getUIFlags: _state => _state.uiFlags,
  hasLoaded: _state => _state.hasLoaded,
};

const normalizeQuestionnaire = (entries = [], fallback = []) => {
  if (Array.isArray(entries) && entries.length) {
    return entries.map(item => ({
      question: item?.question || '',
      description: item?.description || '',
    }));
  }

  if (Array.isArray(fallback) && fallback.length) {
    return fallback.map(item => ({
      question: item?.question || '',
      description: item?.description || '',
    }));
  }

  return [];
};

const serializeContest = payload => {
  const data = {
    name: payload.name,
    trigger_words: payload.trigger_words || [],
  };

  if (payload.start_date) {
    data.start_date = payload.start_date;
  }

  if (payload.end_date) {
    data.end_date = payload.end_date;
  }

  if (payload.description) {
    data.description = payload.description;
  }

  if (payload.terms) {
    data.terms_and_condition = payload.terms;
  }

  if (Array.isArray(payload.questionnaire)) {
    data.questionnaire = payload.questionnaire
      .filter(item => item?.question?.trim())
      .map(item => ({
        question: item.question.trim(),
        description: item?.description?.trim() || undefined,
      }));
  }

  return data;
};

const toDateInputValue = value => {
  if (!value) return '';
  if (typeof value === 'string' && value.includes('T')) {
    return value.split('T')[0];
  }
  return value;
};

const cloneEntries = entries => {
  if (!Array.isArray(entries)) {
    return [];
  }
  return entries.map(entry => ({ ...entry }));
};

const normalizeContest = (record = {}, fallback = {}) => ({
  id: record.id || fallback.id,
  name: record.name || fallback.name || '',
  trigger_words: Array.isArray(record.trigger_words)
    ? record.trigger_words
    : fallback.trigger_words || [],
  dealership: record.dealership || fallback.dealership || '',
  start_date: toDateInputValue(
    record.start_date || fallback.start_date || record.created_at || ''
  ),
  end_date: toDateInputValue(
    record.end_date ||
      fallback.end_date ||
      record.updated_at ||
      record.created_at ||
      ''
  ),
  description: record.description || fallback.description || '',
  terms: record.terms || record.terms_and_condition || fallback.terms || '',
  questionnaire: normalizeQuestionnaire(
    record.questionnaire,
    fallback.questionnaire
  ),
  entries: cloneEntries(record.entries || fallback.entries || []),
  created_at: record.created_at || fallback.created_at,
  updated_at: record.updated_at || fallback.updated_at,
});

const setUiFlag = (commit, flagData) => {
  commit(types.SET_CONTESTS_UI_FLAG, flagData);
};

const actions = {
  async fetch({ commit, state: localState }, { force } = {}) {
    if (!force && localState.hasLoaded) {
      logDebug('fetch skipped (cached)');
      return;
    }

    setUiFlag(commit, { isFetching: true });
    try {
      logDebug('fetch:start', { force });
      const response = await ContestsAPI.index();
      const contests = response?.data?.data || [];
      logDebug('fetch:success', { count: contests.length, response });
      const normalized = contests
        .map(contest => normalizeContest(contest))
        .sort((a, b) => {
          const timeA = a.created_at ? new Date(a.created_at).getTime() : 0;
          const timeB = b.created_at ? new Date(b.created_at).getTime() : 0;
          return timeB - timeA;
        });
      commit(types.SET_CONTESTS, normalized);
      commit(types.SET_CONTESTS_META, {
        hasLoaded: true,
      });
    } catch (error) {
      logDebug('fetch:error', error);
      throwErrorMessage(error);
      throw error;
    } finally {
      setUiFlag(commit, { isFetching: false });
    }
  },
  async create({ commit }, { payload }) {
    setUiFlag(commit, { isCreating: true });
    try {
      logDebug('create:start', { payload });
      const requestPayload = serializeContest(payload);
      const response = await ContestsAPI.create(requestPayload);
      logDebug('create:response', response?.data);
      const contest = response?.data?.data || {};
      const normalized = normalizeContest(contest, {
        ...payload,
      });
      commit(types.ADD_CONTEST, normalized);
      commit(types.SET_CONTESTS_META, {
        hasLoaded: true,
      });
      logDebug('create:success', normalized);
    } catch (error) {
      logDebug('create:error', error);
      throwErrorMessage(error);
      throw error;
    } finally {
      setUiFlag(commit, { isCreating: false });
    }
  },
  async update({ commit, state: localState }, { id, payload }) {
    setUiFlag(commit, { isUpdating: true });
    try {
      logDebug('update:start', { id, payload });
      const requestPayload = serializeContest(payload);
      const response = await ContestsAPI.update(id, requestPayload);
      logDebug('update:response', response?.data);
      const apiContest = response?.data?.data || {};
      const existing = localState.records.find(item => item.id === id) || {};
      const normalized = normalizeContest(apiContest, {
        id,
        ...existing,
        ...payload,
      });
      commit(types.UPDATE_CONTEST, normalized);
      logDebug('update:success', normalized);
    } catch (error) {
      logDebug('update:error', error);
      throwErrorMessage(error);
      throw error;
    } finally {
      setUiFlag(commit, { isUpdating: false });
    }
  },
  async delete({ commit }, { id }) {
    setUiFlag(commit, { isDeleting: true });
    try {
      logDebug('delete:start', { id });
      await ContestsAPI.delete(id);
      commit(types.DELETE_CONTEST, id);
      logDebug('delete:success', id);
    } catch (error) {
      logDebug('delete:error', error);
      throwErrorMessage(error);
      throw error;
    } finally {
      setUiFlag(commit, { isDeleting: false });
    }
  },
  async fetchContestCustomers({ commit }, { params = {} } = {}) {
    if (!Object.keys(params).length) {
      return null;
    }
    setUiFlag(commit, { isCustomersFetching: true });
    try {
      const response = await ContestsAPI.report(params);
      return response?.data?.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      setUiFlag(commit, { isCustomersFetching: false });
    }
  },
};

const mutations = {
  [types.SET_CONTESTS_UI_FLAG](_state, data) {
    _state.uiFlags = { ..._state.uiFlags, ...data };
  },
  [types.SET_CONTESTS_META](_state, data) {
    _state.hasLoaded = data.hasLoaded;
  },
  [types.SET_CONTESTS](_state, data) {
    _state.records = data;
  },
  [types.ADD_CONTEST](_state, record) {
    _state.records = [record, ..._state.records];
  },
  [types.UPDATE_CONTEST](_state, record) {
    _state.records = _state.records.map(existing =>
      existing.id === record.id ? record : existing
    );
  },
  [types.DELETE_CONTEST](_state, id) {
    _state.records = _state.records.filter(record => record.id !== id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
