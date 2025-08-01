import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { createStore } from './storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { getUnixTime, parseISO } from 'date-fns';

const formatDocument = (doc) => {
  if (!doc) return null;
  return {
    ...doc,
    created_at: doc.created_at ? getUnixTime(parseISO(doc.created_at + 'Z')) : null,
    updated_at: doc.updated_at ? getUnixTime(parseISO(doc.updated_at + 'Z')) : null,
    external_link: doc.location, // Map location to external_link for backwards compatibility
  };
};

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
  actions: mutations => ({
    get: async function get({ commit }, params = {}) {
      commit(mutations.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await CaptainDocumentAPI.get(params);
        const payload = response.data.data || [];
        const formattedPayload = Array.isArray(payload) ? payload.map(formatDocument) : [formatDocument(payload)];
        commit(mutations.SET, formattedPayload);
        commit(mutations.SET_META, { total_count: formattedPayload.length, page: 1 });
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return formattedPayload;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return throwErrorMessage(error);
      }
    },

    create: async function create({ commit }, data) {
      commit(mutations.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await CaptainDocumentAPI.create(data);
        const payload = formatDocument(response.data.data);
        commit(mutations.ADD, payload);
        commit(mutations.SET_UI_FLAG, { creatingItem: false });
        return payload;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { creatingItem: false });
        return throwErrorMessage(error);
      }
    },

    delete: async function remove({ commit }, id) {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await CaptainDocumentAPI.delete(id);
        commit(mutations.DELETE, id);
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return id;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return throwErrorMessage(error);
      }
    },
  }),
});
