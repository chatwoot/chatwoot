import axios from 'axios';
import StoreEntity from './entities/StoreEntity';

class ChatscommerceStoreApi {
  constructor() {
    this.apiUrl = `${window.chatwootConfig.chatscommerceApiUrl}/api/stores/`;
  }

  static getHeaders() {
    return {
      'Content-Type': 'application/json',
      Authorization: 'application/json',
    };
  }

  async createStore(account, user_email) {
    const store = new StoreEntity(account, user_email);
    const response = await axios.put(
      `${this.apiUrl}`,
      { store: store.toJSON() },
      { headers: this.constructor.getHeaders() }
    );
    return response.data;
  }
}

export default new ChatscommerceStoreApi();
