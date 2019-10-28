import Vue from 'vue';
import Vuex from 'vuex';
import conversation from 'widget/store/modules/conversation';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    conversation,
  },
});
