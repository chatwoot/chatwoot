import { API } from 'widget/helpers/axios';
import Vue from 'vue';

export default {
  create(name) {
    const locale = Vue.config.lang;
    let search = window.location.search;
    if (search) {
      search = `${search}&locale=${locale}`;
    } else {
      search = `?locale=${locale}`;
    }

    return API.post(`/api/v1/widget/events${search}`, { name });
  },
};
