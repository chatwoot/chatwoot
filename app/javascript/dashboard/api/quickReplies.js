import ApiClient from './ApiClient';

class QuickReplies extends ApiClient {
  constructor() {
    super('quick_replies', { accountScoped: true });
  }

  show() {
    return axios.get(this.url);
  }

  create({ name, content }) {
    return axios.post(this.url, {
      name,
      content,
    });
  }

  update({ id, name, content }) {
    return axios.put(`${this.url}/${id}`, {
      name,
      content,
    });
  }

  destroy({ id }) {
    return axios.destroy(`${this.url}/${id}`);
  }
}

export default new QuickReplies();
