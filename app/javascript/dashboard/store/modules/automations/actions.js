import types from '../../mutation-types';
import AutomationApi from '../../../api/automation';

// actions
const actions = {
  saveAutomation: async ({ commit }, payload) => {
    commit(types.SET_LIST_LOADING_STATUS);
    try {
      const { data } = await AutomationApi.saveAutomation(payload);
      console.log('data', data);
    } catch (error) {
      // Handle error
    }
  },
};

export default actions;
