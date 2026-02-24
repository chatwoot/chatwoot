import { createStore } from 'vuex';
import globalConfig from 'shared/store/globalConfig';

export default createStore({
  modules: {
    globalConfig,
  },
});
