/* global axios */

import ApiClient from './ApiClient';

export const buildCannedPayload = ({ content, shortCode, files }) => {
  let payload;
  if (files && files.length !== 0) {
    payload = new FormData();
    payload.append('canned_response[content]', content);
    payload.append('canned_response[short_code]', shortCode);

    files.forEach(file => {
      payload.append('canned_response[attachments][]', file);
    });
  } else {
    payload = {
      content: content,
      short_code: shortCode,
    };
  }
  return payload;
};

class CannedResponse extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get({ searchKey }) {
    const url = searchKey ? `${this.url}?search=${searchKey}` : this.url;
    return axios.get(url);
  }

  create({ content, shortCode, files }) {
    return axios({
      method: 'post',
      url: this.url,
      data: buildCannedPayload({
        content,
        shortCode,
        files,
      }),
    });
  }

  update({ id, content, shortCode, files }) {
    return axios({
      method: 'patch',
      url: `${this.url}/${id}`,
      data: buildCannedPayload({
        content,
        shortCode,
        files,
      }),
    });
  }
}

export default new CannedResponse();
