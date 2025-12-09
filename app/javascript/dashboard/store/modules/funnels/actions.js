import {
  SET_FUNNEL_UI_FLAG,
  CLEAR_FUNNELS,
  SET_FUNNELS,
  SET_FUNNEL_ITEM,
  EDIT_FUNNEL,
  DELETE_FUNNEL,
  SET_FUNNEL_CONTACTS,
  UPDATE_FUNNEL_CONTACT,
  REMOVE_FUNNEL_CONTACT,
} from './types';
import FunnelsAPI from '../../../api/funnels';

export const actions = {
  create: async ({ commit }, funnelInfo) => {
    commit(SET_FUNNEL_UI_FLAG, { isCreating: true });
    try {
      const response = await FunnelsAPI.create({ funnel: funnelInfo });
      const funnel = response.data;
      commit(SET_FUNNEL_ITEM, funnel);
      return funnel;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_FUNNEL_UI_FLAG, { isCreating: false });
    }
  },

  get: async ({ commit }) => {
    commit(SET_FUNNEL_UI_FLAG, { isFetching: true });
    try {
      const response = await FunnelsAPI.get();
      const data = response?.data || [];
      commit(CLEAR_FUNNELS);
      commit(SET_FUNNELS, Array.isArray(data) ? data : []);
    } catch (error) {
      commit(CLEAR_FUNNELS);
      commit(SET_FUNNELS, []);
      throw error;
    } finally {
      commit(SET_FUNNEL_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(SET_FUNNEL_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await FunnelsAPI.show(id);
      commit(SET_FUNNEL_ITEM, response.data);
      commit(SET_FUNNEL_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_FUNNEL_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(SET_FUNNEL_UI_FLAG, { isUpdating: true });
    try {
      const response = await FunnelsAPI.update(id, { funnel: updateObj });
      commit(EDIT_FUNNEL, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_FUNNEL_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, funnelId) => {
    commit(SET_FUNNEL_UI_FLAG, { isDeleting: true });
    try {
      await FunnelsAPI.delete(funnelId);
      commit(DELETE_FUNNEL, funnelId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_FUNNEL_UI_FLAG, { isDeleting: false });
    }
  },

  getContacts: async ({ commit }, { funnelId }) => {
    try {
      const { data } = await FunnelsAPI.getContacts(funnelId);
      commit(SET_FUNNEL_CONTACTS, { funnelId, contacts: data || [] });
    } catch (error) {
      commit(SET_FUNNEL_CONTACTS, { funnelId, contacts: [] });
      throw error;
    }
  },

  moveContact: async (
    { commit, state },
    { funnelId, contactId, columnId, position }
  ) => {
    // Optimistic update: salva estado atual e atualiza a UI imediatamente
    const funnel = state.records[funnelId];
    let previousContacts = null;

    if (funnel && funnel.contacts) {
      previousContacts = [...funnel.contacts];
      const contacts = [...funnel.contacts];
      const contactIndex = contacts.findIndex(c => c.contact_id === contactId);

      if (contactIndex !== -1) {
        const contact = { ...contacts[contactIndex] };
        const oldColumnId = contact.column_id;
        contact.column_id = columnId;
        contact.position = position;

        // Remove da coluna antiga
        contacts.splice(contactIndex, 1);

        // Reordena contatos na coluna de origem
        contacts
          .filter(c => c.column_id === oldColumnId)
          .forEach((c, idx) => {
            c.position = idx;
          });

        // Insere na posição correta na nova coluna
        const targetContacts = contacts.filter(c => c.column_id === columnId);
        const targetIndex = targetContacts.findIndex(
          c => (c.position || 0) >= position
        );

        if (targetIndex === -1) {
          contacts.push(contact);
        } else {
          const insertIndex = contacts.findIndex(
            c => c.column_id === columnId && (c.position || 0) >= position
          );
          if (insertIndex === -1) {
            contacts.push(contact);
          } else {
            contacts.splice(insertIndex, 0, contact);
          }
        }

        // Reordena contatos na coluna de destino
        contacts
          .filter(c => c.column_id === columnId)
          .forEach((c, idx) => {
            c.position = idx;
          });

        commit(SET_FUNNEL_CONTACTS, { funnelId, contacts });
      }
    }

    try {
      const { data } = await FunnelsAPI.moveContact(
        funnelId,
        contactId,
        columnId,
        position
      );
      // Atualiza com os dados do servidor
      commit(UPDATE_FUNNEL_CONTACT, { funnelId, contact: data });
      return data;
    } catch (error) {
      // Reverte em caso de erro
      if (previousContacts) {
        commit(SET_FUNNEL_CONTACTS, { funnelId, contacts: previousContacts });
      }
      throw new Error(error);
    }
  },

  addContact: async ({ commit }, { funnelId, contactId, columnId }) => {
    try {
      const { data } = await FunnelsAPI.addContact(
        funnelId,
        contactId,
        columnId
      );
      commit(UPDATE_FUNNEL_CONTACT, { funnelId, contact: data });
      return data;
    } catch (error) {
      throw new Error(error);
    }
  },

  removeContact: async ({ commit }, { funnelId, contactId }) => {
    try {
      await FunnelsAPI.removeContact(funnelId, contactId);
      commit(REMOVE_FUNNEL_CONTACT, { funnelId, contactId });
    } catch (error) {
      throw new Error(error);
    }
  },
};
