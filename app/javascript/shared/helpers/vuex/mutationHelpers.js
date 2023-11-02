import Vue from 'vue';

export const set = (state, data) => {
  state.records = data;
};

export const create = (state, data) => {
  state.records.push(data);
};

export const setSingleRecord = (state, data) => {
  const recordIndex = state.records.findIndex(record => record.id === data.id);
  if (recordIndex > -1) {
    state.records[recordIndex] = data;
  } else {
    create(state, data);
  }
};

export const update = (state, data) => {
  state.records.forEach((element, index) => {
    if (element.id === data.id) {
      Vue.set(state.records, index, data);
    }
  });
};

/* when you don't want to overwrite the whole object */
export const updateAttributes = (state, data) => {
  state.records.forEach((element, index) => {
    if (element.id === data.id) {
      Vue.set(state.records, index, { ...state.records[index], ...data });
    }
  });
};

export const updatePresence = (state, data) => {
  state.records.forEach((element, index) => {
    const availabilityStatus = data[element.id];
    Vue.set(
      state.records[index],
      'availability_status',
      availabilityStatus || 'offline'
    );
  });
};

export const updateSingleRecordPresence = (
  records,
  { id, availabilityStatus }
) => {
  const [selectedRecord] = records.filter(record => record.id === Number(id));
  if (selectedRecord) {
    Vue.set(selectedRecord, 'availability_status', availabilityStatus);
  }
};

export const destroy = (state, id) => {
  state.records = state.records.filter(record => record.id !== id);
};

export const appendItems = (state, entity, items) => {
  items.forEach(item => {
    Vue.set(state[entity].byId, item.id, item);
  });
};

export const appendItemIds = (state, entity, items = []) => {
  const itemIds = items.map(item => item.id);
  const allIds = state[entity].allIds;
  const newIds = [...allIds, ...itemIds];
  const uniqIds = Array.from(new Set(newIds));

  Vue.set(state[entity], 'allIds', uniqIds);
};

export const updateItemEntry = (state, entity, item) => {
  const itemId = item.id;
  if (!itemId) return;

  const itemById = state[entity].byId[itemId];
  if (!itemById) return;

  Vue.set(state[entity].byId, itemId, { ...itemById, ...item });
};

export const removeItemEntry = (state, entity, itemId) => {
  if (!itemId) return;

  Vue.delete(state[entity].byId, itemId);
};

export const removeItemId = (state, entity, itemId) => {
  if (!itemId) return;

  state[entity].allIds = state[entity].allIds.filter(id => id !== itemId);
};

export const setItemUIFlag = (state, entity, itemId, uiFlags) => {
  const flags = state[entity].uiFlags.byId[itemId];
  state[entity].uiFlags.byId[itemId] = {
    ...flags,
    ...uiFlags,
  };
};
