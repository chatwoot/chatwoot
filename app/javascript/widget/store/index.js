import Vue from 'vue';
import Vuex from 'vuex';
import conversation from 'widget/store/modules/conversation';
import appConfig from 'widget/store/modules/appConfig';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    appConfig,
    conversation,
  },
});
