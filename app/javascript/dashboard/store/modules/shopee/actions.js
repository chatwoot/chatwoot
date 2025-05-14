import {
  SET_SHOPEE_UI_FLAG,
  GET_ORDERS,
  GET_VOUCHERS,
  SEARCH_PRODUCTS,
  SEND_ORDER_MESSAGE,
  SEND_VOUCHER_MESSAGE,
  SEND_PRODUCT_MESSAGE,
} from './types';
import ShopeeAPI from '../../../api/inbox/shopee';

export const actions = {
  getOrders: async ({ commit }, { conversationID, orderStatus }) => {
    commit(SET_SHOPEE_UI_FLAG, { isFetchingOrders: true });
    try {
      const response = await ShopeeAPI.getOrders({
        conversationID,
        orderStatus,
      });
      commit(GET_ORDERS, response.data.payload);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_SHOPEE_UI_FLAG, { isFetchingOrders: false });
    }
  },
  getVouchers: async ({ commit }, { conversationID }) => {
    commit(SET_SHOPEE_UI_FLAG, { isFetchingVouchers: true });
    try {
      const response = await ShopeeAPI.getVouchers({ conversationID });
      commit(GET_VOUCHERS, response.data.payload);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_SHOPEE_UI_FLAG, { isFetchingVouchers: false });
    }
  },
  searchProducts: async ({ commit }, { conversationID, keyword }) => {
    commit(SET_SHOPEE_UI_FLAG, { isSearchingProducts: true });
    try {
      const response = await ShopeeAPI.searchProducts(conversationID, keyword);
      commit(SEARCH_PRODUCTS, response.data.payload);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_SHOPEE_UI_FLAG, { isSearchingProducts: false });
    }
  },
  sendOrderMessage: async ({ commit }, { conversationId, orderId }) => {
    commit(SET_SHOPEE_UI_FLAG, { isSendingOrderMessage: true });
    try {
      const response = await ShopeeAPI.sendOrder(conversationId, orderId);
      commit(SEND_ORDER_MESSAGE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_SHOPEE_UI_FLAG, { isSendingOrderMessage: false });
    }
  },
  sendVoucherMessage: async ({ commit }, { conversationId, voucherId }) => {
    commit(SET_SHOPEE_UI_FLAG, { isSendingVoucherMessage: true });
    try {
      const response = await ShopeeAPI.sendVoucher(conversationId, voucherId);
      commit(SEND_VOUCHER_MESSAGE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_SHOPEE_UI_FLAG, { isSendingVoucherMessage: false });
    }
  },
  sendProductMessage: async ({ commit }, { conversationId, productIds }) => {
    commit(SET_SHOPEE_UI_FLAG, { isSendingProductMessage: true });
    try {
      const response = await ShopeeAPI.sendProduct(conversationId, productIds);
      commit(SEND_PRODUCT_MESSAGE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_SHOPEE_UI_FLAG, { isSendingProductMessage: false });
    }
  },
};
