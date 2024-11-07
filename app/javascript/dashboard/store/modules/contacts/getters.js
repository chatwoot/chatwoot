import camelcaseKeys from 'camelcase-keys';

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
  getContactById: $state => id => {
    const contact = $state.records[id];
    return camelcaseKeys(contact || {});
  },
  getMeta: $state => {
    return $state.meta;
  },
  getAppliedContactFilters: _state => {
    return _state.appliedFilters;
  },
};
