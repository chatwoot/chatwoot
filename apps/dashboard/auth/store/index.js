import Vue from 'vue';
import Vuex from 'vuex';
import globalConfig from 'shared/store/globalConfig';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    globalConfig,
  },
});
