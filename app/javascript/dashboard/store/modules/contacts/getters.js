export const getters = {
  getContacts($state) {
    return $state.sortOrder.map(contactId => $state.records[contactId]);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContact: $state => id => {
    const contact = $state.records[id];
    return contact || {};
  },
  getTransactions: $state => id => {
    const contact = $state.records[id];
    return contact.transactions || {};
  },
  getMeta: $state => {
    return $state.meta;
  },
  getStageMeta: $state => {
    return $state.stageMeta;
  },
  getAppliedContactFilters: _state => {
    return _state.appliedFilters;
  },
};
