import types from '../../mutation-types';
import * as Sentry from '@sentry/vue';

// Channels whose contact_inbox source_id derives from an identifying address
// of the contact (see Contacts::ContactableInboxesService and
// ContactInboxBuilder): their entries go stale when that address changes.
const EMAIL_CHANNELS = ['Channel::Email'];
const PHONE_CHANNELS = [
  'Channel::Whatsapp',
  'Channel::Sms',
  'Channel::TwilioSms',
];

export const mutations = {
  [types.SET_CONTACT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_CONTACTS]: $state => {
    $state.records = {};
    $state.sortOrder = [];
  },

  [types.SET_CONTACT_META]: ($state, data) => {
    const { count, current_page: currentPage, has_more: hasMore } = data;
    $state.meta.count = count;
    $state.meta.currentPage = currentPage;
    if (hasMore !== undefined) {
      $state.meta.hasMore = hasMore;
    }
  },

  [types.APPEND_CONTACTS]: ($state, data) => {
    data.forEach(contact => {
      $state.records[contact.id] = {
        ...($state.records[contact.id] || {}),
        ...contact,
      };
      if (!$state.sortOrder.includes(contact.id)) {
        $state.sortOrder.push(contact.id);
      }
    });
  },

  [types.SET_CONTACTS]: ($state, data) => {
    const sortOrder = data.map(contact => {
      $state.records[contact.id] = {
        ...($state.records[contact.id] || {}),
        ...contact,
      };
      return contact.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_CONTACT_ITEM]: ($state, data) => {
    $state.records[data.id] = {
      ...($state.records[data.id] || {}),
      ...data,
    };

    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_CONTACT]: ($state, data) => {
    // Websocket `contact.updated` payloads don't include `contact_inboxes`;
    // preserve them from the existing record so the new conversation modal
    // doesn't lose the list of contactable inboxes. When the payload omits
    // them and an identifying address changed, the channels deriving their
    // source_id from that address are dropped (their entries would point at
    // the stale address) while other channels (API, web widget, …) are
    // kept. Payloads that do carry contact_inboxes are taken as-is.
    const existingContact = $state.records[data.id] || {};
    let contactInboxes = data.contact_inboxes;
    if (!contactInboxes && existingContact.contact_inboxes) {
      // An address only counts as changed when the payload carries the field
      // and a previous value is known — payloads that omit it say nothing.
      const staleChannels = [];
      if (
        data.email !== undefined &&
        existingContact.email &&
        data.email !== existingContact.email
      ) {
        staleChannels.push(...EMAIL_CHANNELS);
      }
      if (
        data.phone_number !== undefined &&
        existingContact.phone_number &&
        data.phone_number !== existingContact.phone_number
      ) {
        staleChannels.push(...PHONE_CHANNELS);
      }
      contactInboxes = existingContact.contact_inboxes.filter(
        contactInbox =>
          !staleChannels.includes(contactInbox.inbox?.channel_type)
      );
    }
    const record = { ...data };
    if (contactInboxes !== undefined) {
      record.contact_inboxes = contactInboxes;
    }
    $state.records[data.id] = record;
  },

  [types.DELETE_CONTACT]: ($state, id) => {
    const index = $state.sortOrder.findIndex(item => item === id);
    $state.sortOrder.splice(index, 1);
    delete $state.records[id];
  },

  [types.UPDATE_CONTACTS_PRESENCE]: ($state, data) => {
    Object.values($state.records).forEach(element => {
      let availabilityStatus;
      try {
        availabilityStatus = data[element.id];
      } catch (error) {
        Sentry.setContext('contact is undefined', {
          records: $state.records,
          data: data,
        });
        Sentry.captureException(error);

        return;
      }
      if (availabilityStatus) {
        $state.records[element.id].availability_status = availabilityStatus;
      } else {
        $state.records[element.id].availability_status = null;
      }
    });
  },

  [types.SET_CONTACT_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.CLEAR_CONTACT_FILTERS](_state) {
    _state.appliedFilters = [];
  },
};
