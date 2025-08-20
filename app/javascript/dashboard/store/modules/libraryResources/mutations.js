import types from '../../mutation-types';

export const mutations = {
  [types.SET_LIBRARY_RESOURCE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_LIBRARY_RESOURCES](_state) {
    _state.records = {};
    _state.sortOrder = [];
  },

  [types.SET_LIBRARY_RESOURCES_META](_state, data) {
    _state.meta = {
      ..._state.meta,
      ...data,
    };
  },

  [types.SET_LIBRARY_RESOURCES](_state, data) {
    const sortOrder = data.map(resource => {
      _state.records[resource.id] = {
        ...(_state.records[resource.id] || {}),
        ...resource,
      };
      return resource.id;
    });
    _state.sortOrder = sortOrder;
  },

  [types.SET_LIBRARY_RESOURCE_ITEM](_state, data) {
    _state.records[data.id] = {
      ...(_state.records[data.id] || {}),
      ...data,
    };
    if (!_state.sortOrder.includes(data.id)) {
      _state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_LIBRARY_RESOURCE](_state, data) {
    _state.records[data.id] = data;
  },

  [types.DELETE_LIBRARY_RESOURCE](_state, id) {
    const index = _state.sortOrder.findIndex(item => item === id);
    _state.sortOrder.splice(index, 1);
    delete _state.records[id];
  },
};
