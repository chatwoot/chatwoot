import { createStore } from 'shared/store/createStore';
import globalConfig from 'shared/store/globalConfig';

export default createStore({
  modules: {
    globalConfig,
  },
});
