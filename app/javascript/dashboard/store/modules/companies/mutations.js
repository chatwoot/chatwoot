import types from '../../mutation-types';

export const mutations = {
  [types.SET_COMPANY_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_COMPANIES]: $state => {
    $state.records = {};
    $state.sortOrder = [];
  },

  [types.SET_COMPANY_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    $state.meta.count = count;
    $state.meta.currentPage = currentPage;
  },

  [types.SET_COMPANIES]: ($state, data) => {
    const sortOrder = data.map(company => {
      $state.records[company.id] = {
        ...($state.records[company.id] || {}),
        ...company,
      };
      return company.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_COMPANY_ITEM]: ($state, data) => {
    $state.records[data.id] = {
      ...($state.records[data.id] || {}),
      ...data,
    };

    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_COMPANY]: ($state, data) => {
    $state.records[data.id] = data;
  },

  [types.DELETE_COMPANY]: ($state, id) => {
    const index = $state.sortOrder.findIndex(item => item === id);
    $state.sortOrder.splice(index, 1);
    delete $state.records[id];
  },
};
