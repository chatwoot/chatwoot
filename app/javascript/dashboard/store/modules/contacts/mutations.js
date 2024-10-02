import types from '../../mutation-types';

export const mutations = {
  [types.SET_CONTACT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_CONTACTS]: $state => {
    $state.records = {};
    $state.sortOrder = [];
  },

  [types.SET_CONTACT_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    $state.meta.count = count;
    $state.meta.currentPage = currentPage;
  },

  [types.SET_CONTACTS]: ($state, data) => {
    const sortOrder = data.map(contact => {
      $state.records[contact.id] = {
        ...($state.records[contact.id] || {}),
        ...contact,
      };
      return contact.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_CONTACT_ITEM]: ($state, data) => {
    $state.records[data.id] = {
      ...($state.records[data.id] || {}),
      ...data,
    };

    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_CONTACT]: ($state, data) => {
    $state.records[data.id] = data;
  },

  [types.DELETE_CONTACT]: ($state, id) => {
    const index = $state.sortOrder.findIndex(item => item === id);
    $state.sortOrder.splice(index, 1);
    $state.records[id] = null;
  },

  [types.UPDATE_CONTACTS_PRESENCE]: ($state, data) => {
    Object.values($state.records).forEach(element => {
      const availabilityStatus = data[element.id];
      if (availabilityStatus) {
        $state.records[element.id].availability_status = availabilityStatus;
      } else {
        $state.records[element.id].availability_status = null;
      }
    });
  },

  [types.SET_CONTACT_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.CLEAR_CONTACT_FILTERS](_state) {
    _state.appliedFilters = [];
  },
};
