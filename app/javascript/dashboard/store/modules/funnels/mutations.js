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

export const mutations = {
  [SET_FUNNEL_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [CLEAR_FUNNELS]: $state => {
    $state.records = {};
  },

  [SET_FUNNELS]: ($state, data) => {
    const updatedRecords = { ...$state.records };
    data.forEach(funnel => {
      updatedRecords[funnel.id] = {
        ...(updatedRecords[funnel.id] || {}),
        ...funnel,
      };
    });
    $state.records = updatedRecords;
  },

  [SET_FUNNEL_ITEM]: ($state, data) => {
    $state.records = {
      ...$state.records,
      [data.id]: {
        ...($state.records[data.id] || {}),
        ...data,
      },
    };
  },

  [EDIT_FUNNEL]: ($state, data) => {
    $state.records = {
      ...$state.records,
      [data.id]: data,
    };
  },

  [DELETE_FUNNEL]: ($state, funnelId) => {
    const { [funnelId]: toDelete, ...records } = $state.records;
    $state.records = records;
  },

  [SET_FUNNEL_CONTACTS]: ($state, { funnelId, contacts }) => {
    if (!$state.records[funnelId]) {
      $state.records[funnelId] = {};
    }
    $state.records[funnelId].contacts = contacts;
  },

  [UPDATE_FUNNEL_CONTACT]: ($state, { funnelId, contact }) => {
    if (!$state.records[funnelId] || !$state.records[funnelId].contacts) {
      return;
    }
    const contacts = $state.records[funnelId].contacts || [];
    const index = contacts.findIndex(c => c.contact_id === contact.contact_id);
    if (index !== -1) {
      contacts[index] = contact;
    } else {
      contacts.push(contact);
    }
    $state.records[funnelId].contacts = [...contacts];
  },

  [REMOVE_FUNNEL_CONTACT]: ($state, { funnelId, contactId }) => {
    if (!$state.records[funnelId] || !$state.records[funnelId].contacts) {
      return;
    }
    $state.records[funnelId].contacts = $state.records[
      funnelId
    ].contacts.filter(c => c.contact_id !== contactId);
  },
};
