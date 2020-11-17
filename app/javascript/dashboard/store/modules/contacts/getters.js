export const getters = {
  getContacts($state) {
    return Object.values($state.records);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContact: $state => id => {
    const contact = $state.records[id];
    return contact || {};
  },
  getMeta: $state => {
    return $state.meta;
  },
};
