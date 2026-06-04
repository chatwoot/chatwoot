/* global axios */
import ApiClient from './ApiClient';

class WhatsappStickersApi extends ApiClient {
  constructor() {
    super('whatsapp_stickers', { accountScoped: true });
  }

  getStickers(inboxId) {
    return axios.get(`${this.url}?inbox_id=${inboxId}`);
  }

  createSticker(inboxId, blobSignedId) {
    return axios.post(this.url, {
      whatsapp_sticker: {
        inbox_id: inboxId,
        blob_signed_id: blobSignedId,
      },
    });
  }

  deleteSticker(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  bulkDelete(ids) {
    return axios.delete(`${this.url}/bulk_destroy`, { data: { ids } });
  }
}

export default new WhatsappStickersApi();
