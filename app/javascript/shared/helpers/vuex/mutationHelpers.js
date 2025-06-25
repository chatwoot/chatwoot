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
