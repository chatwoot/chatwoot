import { createStore } from '../storeFactory';
import CaptainToolsAPI from '../../api/captain/tools';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';

const toolsStore = createStore({
  name: 'Tools',
  API: CaptainToolsAPI,
  actions: mutations => {
    const { run } = useAbortableRequest();

    return {
      getTools: async ({ commit }, { assistantId }) => {
        commit(mutations.SET, []);
        commit(mutations.SET_UI_FLAG, { fetchingList: true });
        try {
          return await run(async signal => {
            try {
              const response = await CaptainToolsAPI.get({
                assistant_id: assistantId,
                signal,
              });
              if (signal.aborted) return null;

              commit(mutations.SET, response.data);
              return response.data;
            } finally {
              if (!signal.aborted) {
                commit(mutations.SET_UI_FLAG, { fetchingList: false });
              }
            }
          });
        } catch (error) {
          return throwErrorMessage(error);
        }
      },
    };
  },
});

export default toolsStore;
