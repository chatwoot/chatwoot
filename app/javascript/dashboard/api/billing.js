/* global axios */

import ApiClient from './ApiClient';

class BillingAPI extends ApiClient  {
  constructor() {
    super('subscriptions', { accountScoped: true });
  }
//   profileUpdate({
//     password,
//     password_confirmation,
//     displayName,
//     avatar,
//     ...profileAttributes
//   }) {
//     const formData = new FormData();
//     Object.keys(profileAttributes).forEach(key => {
//       const hasValue = profileAttributes[key] === undefined;
//       if (!hasValue) {
//         formData.append(`profile[${key}]`, profileAttributes[key]);
//       }
//     });
//     formData.append('profile[display_name]', displayName || '');
//     if (password && password_confirmation) {
//       formData.append('profile[password]', password);
//       formData.append('profile[password_confirmation]', password_confirmation);
//     }
//     if (avatar) {
//       formData.append('profile[avatar]', avatar);
//     }
//     return axios.put(endPoints('profileUpdate').url, formData);
//   },

myActiveSubscription() {
    return axios.get(this.url);
  }
};

export default new BillingAPI();
