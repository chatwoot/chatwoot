import InternalTasksAPI from '../../api/internalTasks';
import TaskTemplatesAPI from '../../api/taskTemplates';
import camelcaseKeys from 'camelcase-keys';
import {
  TASK_TAB_TYPE,
  TASK_STATUS_FILTER,
  OPEN_TASK_STATUSES,
  taskListParams,
} from '../../helper/internalTaskUi';

const SET_UI_FLAG = 'SET_INTERNAL_TASKS_UI_FLAG';
const SET_CONVERSATION_TASKS = 'SET_CONVERSATION_TASKS';
const SET_ACCOUNT_TASKS = 'SET_ACCOUNT_TASKS';
const SET_LIST_QUERY = 'SET_LIST_QUERY';
const SET_TASK_TEMPLATES = 'SET_TASK_TEMPLATES';
const SET_SELECTED_TASK = 'SET_SELECTED_TASK';
const SET_TAB_COUNTS = 'SET_TAB_COUNTS';
const ADD_CONVERSATION_TASK = 'ADD_CONVERSATION_TASK';
const UPDATE_TASK = 'UPDATE_TASK';
const CLEAR_SELECTED_TASK = 'CLEAR_INTERNAL_TASKS_SELECTED';

export const state = {
  conversationRecords: {},
  accountRecords: [],
  listQuery: {},
  selectedTaskRecord: null,
  tabCounts: {
    [TASK_TAB_TYPE.MINE]: 0,
    [TASK_TAB_TYPE.UNCLAIMED]: 0,
    [TASK_TAB_TYPE.ALL]: 0,
  },
  templates: [],
  uiFlags: {
    isFetchingList: false,
    isFetchingTask: false,
    isCreating: false,
    isUpdating: false,
  },
};

export const getters = {
  getConversationTasks: _state => conversationId =>
    camelcaseKeys(_state.conversationRecords[conversationId] || [], {
      deep: true,
    }),
  getAccountTasks: _state =>
    camelcaseKeys(_state.accountRecords, { deep: true }),
  getTaskById: _state => taskId => {
    const id = Number(taskId);
    const fromList = _state.accountRecords.find(task => task.id === id);
    if (fromList) return camelcaseKeys(fromList, { deep: true });
    if (_state.selectedTaskRecord?.id === id) {
      return camelcaseKeys(_state.selectedTaskRecord, { deep: true });
    }
    return null;
  },
  getSelectedTask: _state =>
    _state.selectedTaskRecord
      ? camelcaseKeys(_state.selectedTaskRecord, { deep: true })
      : null,
  getTaskTemplates: _state => camelcaseKeys(_state.templates, { deep: true }),
  getTabCounts: _state => _state.tabCounts,
  getUIFlags: _state => _state.uiFlags,
  getMyOpenTaskCount: _state => _state.tabCounts[TASK_TAB_TYPE.MINE] || 0,
};

const upsertTaskRecord = (_state, { conversationId, data }) => {
  if (conversationId) {
    const existing = _state.conversationRecords[conversationId] || [];
    const index = existing.findIndex(task => task.id === data.id);
    if (OPEN_TASK_STATUSES.includes(data.status)) {
      if (index >= 0) {
        const next = [...existing];
        next[index] = data;
        _state.conversationRecords[conversationId] = next;
      } else {
        _state.conversationRecords[conversationId] = [data, ...existing];
      }
    } else {
      _state.conversationRecords[conversationId] = existing.filter(
        task => task.id !== data.id
      );
    }
  }

  const index = _state.accountRecords.findIndex(task => task.id === data.id);
  if (OPEN_TASK_STATUSES.includes(data.status)) {
    if (index >= 0) {
      const next = [..._state.accountRecords];
      next[index] = data;
      _state.accountRecords = next;
    } else {
      _state.accountRecords = [data, ..._state.accountRecords];
    }
  } else if (index >= 0) {
    _state.accountRecords = _state.accountRecords.filter(
      task => task.id !== data.id
    );
  }

  if (_state.selectedTaskRecord?.id === data.id) {
    _state.selectedTaskRecord = data;
  }
};

export const actions = {
  async fetchConversationTasks({ commit }, { conversationId }) {
    commit(SET_UI_FLAG, { isFetchingList: true });
    try {
      const { data } = await InternalTasksAPI.getByConversation(conversationId);
      commit(SET_CONVERSATION_TASKS, { conversationId, data });
    } finally {
      commit(SET_UI_FLAG, { isFetchingList: false });
    }
  },

  async createConversationTask(
    { commit, dispatch },
    { conversationId, payload }
  ) {
    commit(SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await InternalTasksAPI.createForConversation(
        conversationId,
        payload
      );
      commit(ADD_CONVERSATION_TASK, { conversationId, data });
      dispatch('fetchTabCounts');
      return data;
    } finally {
      commit(SET_UI_FLAG, { isCreating: false });
    }
  },

  async fetchAccountTasks({ commit, dispatch }, params = {}) {
    commit(SET_UI_FLAG, { isFetchingList: true });
    commit(SET_LIST_QUERY, params);
    try {
      const { data } = await InternalTasksAPI.getTasks(params);
      commit(SET_ACCOUNT_TASKS, { data });
      dispatch('fetchTabCounts', { teamId: params.team_id });
    } finally {
      commit(SET_UI_FLAG, { isFetchingList: false });
    }
  },

  async fetchTabCounts({ commit }, { teamId } = {}) {
    const entries = await Promise.all(
      Object.values(TASK_TAB_TYPE).map(async tab => {
        const { data } = await InternalTasksAPI.getTasks(
          taskListParams(tab, teamId, TASK_STATUS_FILTER.OPEN)
        );
        return [tab, data.length];
      })
    );
    commit(SET_TAB_COUNTS, Object.fromEntries(entries));
  },

  async fetchTask({ commit }, { taskId }) {
    commit(SET_UI_FLAG, { isFetchingTask: true });
    try {
      const { data } = await InternalTasksAPI.get(taskId);
      commit(SET_SELECTED_TASK, { data });
      commit(UPDATE_TASK, { data });
      return camelcaseKeys(data, { deep: true });
    } finally {
      commit(SET_UI_FLAG, { isFetchingTask: false });
    }
  },

  async updateTask({ commit, dispatch }, { taskId, conversationId, payload }) {
    commit(SET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await InternalTasksAPI.update(taskId, payload);
      commit(UPDATE_TASK, { conversationId, data });
      commit(SET_SELECTED_TASK, { data });
      dispatch('fetchTabCounts');
      return data;
    } finally {
      commit(SET_UI_FLAG, { isUpdating: false });
    }
  },

  async addTaskComment({ commit }, { taskId, conversationId, comment }) {
    commit(SET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await InternalTasksAPI.addComment(taskId, comment);
      commit(UPDATE_TASK, { conversationId, data });
      commit(SET_SELECTED_TASK, { data });
      return data;
    } finally {
      commit(SET_UI_FLAG, { isUpdating: false });
    }
  },

  async fetchTaskTemplates({ commit }) {
    const { data } = await TaskTemplatesAPI.get();
    commit(SET_TASK_TEMPLATES, { data });
  },

  async claimTask({ commit, dispatch }, { taskId, conversationId }) {
    commit(SET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await InternalTasksAPI.claim(taskId);
      commit(UPDATE_TASK, { conversationId, data });
      commit(SET_SELECTED_TASK, { data });
      dispatch('fetchTabCounts');
      return data;
    } catch (error) {
      if (error?.response?.status === 409) {
        if (conversationId) {
          dispatch('fetchConversationTasks', { conversationId });
        }
        dispatch('fetchTask', { taskId }).catch(() => {});
        dispatch('fetchTabCounts');
      }
      throw error;
    } finally {
      commit(SET_UI_FLAG, { isUpdating: false });
      if (conversationId) {
        dispatch('fetchConversationTasks', { conversationId });
      }
    }
  },

  async startTask({ commit }, { taskId, conversationId }) {
    commit(SET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await InternalTasksAPI.start(taskId);
      commit(UPDATE_TASK, { conversationId, data });
      commit(SET_SELECTED_TASK, { data });
      return data;
    } finally {
      commit(SET_UI_FLAG, { isUpdating: false });
    }
  },

  async completeTask(
    { commit, dispatch },
    { taskId, conversationId, metadata, comment }
  ) {
    commit(SET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await InternalTasksAPI.complete(taskId, {
        metadata,
        comment,
      });
      commit(UPDATE_TASK, { conversationId, data });
      commit(SET_SELECTED_TASK, { data });
      dispatch('fetchTabCounts');
      return data;
    } finally {
      commit(SET_UI_FLAG, { isUpdating: false });
    }
  },

  handleTaskCreated({ commit, dispatch }, payload) {
    const task = payload.internal_task;
    if (!task) return;
    commit(UPDATE_TASK, { data: task });
    dispatch('refreshAccountTasks');
  },

  handleTaskUpdated({ commit, state: moduleState }, payload) {
    const task = payload.internal_task;
    if (!task) return;
    commit(UPDATE_TASK, { data: task });
    if (moduleState.selectedTaskRecord?.id === task.id) {
      commit(SET_SELECTED_TASK, { data: task });
    }
  },

  async refreshAccountTasks({ commit, dispatch, state: moduleState }) {
    const params = moduleState.listQuery || {};
    if (!Object.keys(params).length && !moduleState.accountRecords.length) {
      dispatch('fetchTabCounts');
      return;
    }
    try {
      const { data } = await InternalTasksAPI.getTasks(params);
      commit(SET_ACCOUNT_TASKS, { data });
    } finally {
      dispatch('fetchTabCounts', { teamId: params.team_id });
    }
  },

  clearSelectedState({ commit }) {
    commit(CLEAR_SELECTED_TASK);
  },
};

export const mutations = {
  [SET_UI_FLAG](_state, data) {
    _state.uiFlags = { ..._state.uiFlags, ...data };
  },
  [SET_CONVERSATION_TASKS](_state, { conversationId, data }) {
    _state.conversationRecords = {
      ..._state.conversationRecords,
      [conversationId]: data,
    };
  },
  [SET_ACCOUNT_TASKS](_state, { data }) {
    _state.accountRecords = data;
  },
  [SET_LIST_QUERY](_state, params) {
    _state.listQuery = { ...params };
  },
  [SET_SELECTED_TASK](_state, { data }) {
    _state.selectedTaskRecord = data;
  },
  [CLEAR_SELECTED_TASK](_state) {
    _state.selectedTaskRecord = null;
  },
  [SET_TAB_COUNTS](_state, counts) {
    _state.tabCounts = { ..._state.tabCounts, ...counts };
  },
  [SET_TASK_TEMPLATES](_state, { data }) {
    _state.templates = data;
  },
  [ADD_CONVERSATION_TASK](_state, { conversationId, data }) {
    const existing = _state.conversationRecords[conversationId] || [];
    _state.conversationRecords[conversationId] = [data, ...existing];
  },
  [UPDATE_TASK](_state, { conversationId, data }) {
    upsertTaskRecord(_state, { conversationId, data });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
