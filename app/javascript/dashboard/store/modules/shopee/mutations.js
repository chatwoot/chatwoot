import {
  SET_SHOPEE_UI_FLAG,
  GET_ORDERS,
  GET_VOUCHERS,
  SEARCH_PRODUCTS,
  SEND_ORDER_MESSAGE,
  SEND_VOUCHER_MESSAGE,
  SEND_PRODUCT_MESSAGE,
} from './types';

export const mutations = {
  [SET_SHOPEE_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [GET_ORDERS]: ($state, data) => {
    $state.records = data;
  },
  [GET_VOUCHERS]: ($state, data) => {
    $state.records = data;
  },
  [SEARCH_PRODUCTS]: ($state, data) => {
    $state.records = data;
  },
  [SEND_ORDER_MESSAGE]: $state => {
    $state.records = {};
  },
  [SEND_VOUCHER_MESSAGE]: $state => {
    $state.records = {};
  },
  [SEND_PRODUCT_MESSAGE]: $state => {
    $state.records = {};
  },
};
