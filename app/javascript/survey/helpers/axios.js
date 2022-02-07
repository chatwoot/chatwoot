import axios from 'axios';
import { APP_BASE_URL } from 'widget/helpers/constants';

export const API = axios.create({
  baseURL: APP_BASE_URL,
});
