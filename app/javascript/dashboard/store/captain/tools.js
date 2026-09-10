import { createStore } from '../storeFactory';
import CaptainToolsAPI from '../../api/captain/tools';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const toolsStore = createStore({
  name: 'Tools',
  API: CaptainToolsAPI,
  actions: mutations => ({
    getTools: async ({ commit }, { assistantId }) => {
      commit(mutations.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await CaptainToolsAPI.get({
          assistant_id: assistantId,
        });
        commit(mutations.SET, response.data);
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return throwErrorMessage(error);
      }
    },
  }),
});

export default toolsStore;
