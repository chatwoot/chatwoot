export default class ConfigurationEntity {
  constructor(data, key, id = null, store_id = null) {
    this.id = id;
    this.store_id = store_id;
    this.key = key;
    this.data = data;
  }

  toJSON() {
    return {
      id: this.id,
      key: this.key,
      data: this.data,
      store_id: this.store_id,
    };
  }
}
