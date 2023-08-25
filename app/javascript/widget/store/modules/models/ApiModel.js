import { APP_BASE_URL } from 'widget/helpers/constants';
import { Model } from '@vuex-orm/core';

export default class ApiModel extends Model {
  static apiConfig = {
    baseURL: APP_BASE_URL,
    withCredentials: false,
  };
}
