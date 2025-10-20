import axios from 'axios';
import ApiClient from './ApiClient';

class AppointmentsAPI extends ApiClient {
  constructor() {
    super('appointments', { accountScoped: true });
  }

  validateAppointmentToken(token) {
    return axios.post(`${this.url}/validate_appointment_token`, { token });
  }
}

export default new AppointmentsAPI();
