export default class StoreEntity {
  constructor(account, user_email) {
    this.id = account.store_id;
    this.name = account.name;
    this.email = user_email;
    this.phone = account.phone || '';
    this.useCases = `${account.name}UseCases`;
    this.ecommercePlatform = 'shopify';
    this.isActive = true;
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      email: this.email,
      phone: this.phone,
      useCases: this.useCases,
      ecommercePlatform: this.ecommercePlatform,
      isActive: this.isActive,
    };
  }
}
