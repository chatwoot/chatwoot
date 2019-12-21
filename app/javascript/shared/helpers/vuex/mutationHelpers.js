export const set = (state, data) => {
  state.records = data;
};

export const create = (state, data) => {
  state.records.push(data);
};

export const update = (state, data) => {
  state.records.forEach((element, index) => {
    if (element.id === data.id) {
      state.records[index] = data;
    }
  });
};

export const destroy = (state, id) => {
  state.records = state.records.filter(record => record.id !== id);
};
