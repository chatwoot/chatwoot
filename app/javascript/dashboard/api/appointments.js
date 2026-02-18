/* global axios */
import ApiClient from './ApiClient';

export const buildAppointmentParams = (page, sortAttr, search) => {
  let params = `page=${page}&sort=${sortAttr}`;
  if (search) {
    params = `${params}&q=${search}`;
  }
  return params;
};

class AppointmentsAPI extends ApiClient {
  constructor() {
    super('appointments', { accountScoped: true });
  }

  get(page = 1, sortAttr = '-scheduled_at') {
    const requestURL = `${this.url}?${buildAppointmentParams(page, sortAttr, '')}`;

    return axios.get(requestURL);
  }

  search(search = '', page = 1, sortAttr = '-scheduled_at') {
    const requestURL = `${this.url}/search?${buildAppointmentParams(page, sortAttr, search)}`;
    return axios.get(requestURL);
  }

  filter(payload, page = 1, sortAttr = '-scheduled_at') {
    const requestURL = `${this.url}/filter?${buildAppointmentParams(page, sortAttr, '')}`;
    return axios.post(requestURL, {
      payload,
    });
  }

  validateAppointmentToken(token) {
    return axios.post(`${this.url}/validate_appointment_token`, { token });
  }
}

export default new AppointmentsAPI();
