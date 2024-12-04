import camelcaseKeys from 'camelcase-keys';

export const getters = {
  getContacts($state) {
    return $state.sortOrder.map(contactId => $state.records[contactId]);
  },
  getContactsList($state) {
    const contacts = $state.sortOrder.map(
      contactId => $state.records[contactId]
    );
    return camelcaseKeys(contacts, { deep: true });
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
    return camelcaseKeys(contact || {}, {
      deep: true,
      stopPaths: ['custom_attributes'],
    });
  },
  getMeta: $state => {
    return $state.meta;
  },
  getAppliedContactFilters: _state => {
    return _state.appliedFilters;
  },
  getAppliedContactFiltersV4: _state => {
    return _state.appliedFilters.map(camelcaseKeys);
  },
};
