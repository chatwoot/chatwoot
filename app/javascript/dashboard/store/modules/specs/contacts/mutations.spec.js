import types from '../../../mutation-types';
import Contacts from '../../contacts';
const { mutations } = Contacts;

describe('#mutations', () => {
  describe('#SET_CONTACTS', () => {
    it('set contact records', () => {
      const state = { records: {} };
      mutations[types.SET_CONTACTS](state, [
        { id: 2, name: 'contact2', email: 'contact2@chatwoot.com' },
        { id: 1, name: 'contact1', email: 'contact1@chatwoot.com' },
      ]);
      expect(state.records).toEqual({
        1: {
          id: 1,
          name: 'contact1',
          email: 'contact1@chatwoot.com',
        },
        2: {
          id: 2,
          name: 'contact2',
          email: 'contact2@chatwoot.com',
        },
      });
      expect(state.sortOrder).toEqual([2, 1]);
    });
  });

  describe('#SET_CONTACT_ITEM', () => {
    it('push contact data to the store', () => {
      const state = {
        records: {
          1: { id: 1, name: 'contact1', email: 'contact1@chatwoot.com' },
        },
        sortOrder: [1],
      };
      mutations[types.SET_CONTACT_ITEM](state, {
        id: 2,
        name: 'contact2',
        email: 'contact2@chatwoot.com',
      });
      expect(state.records).toEqual({
        1: { id: 1, name: 'contact1', email: 'contact1@chatwoot.com' },
        2: { id: 2, name: 'contact2', email: 'contact2@chatwoot.com' },
      });
      expect(state.sortOrder).toEqual([1, 2]);
    });
  });

  describe('#EDIT_CONTACT', () => {
    it('update contact', () => {
      const state = {
        records: {
          1: { id: 1, name: 'contact1', email: 'contact1@chatwoot.com' },
        },
      };
      mutations[types.EDIT_CONTACT](state, {
        id: 1,
        name: 'contact2',
        email: 'contact2@chatwoot.com',
      });
      expect(state.records).toEqual({
        1: { id: 1, name: 'contact2', email: 'contact2@chatwoot.com' },
      });
    });

    it('preserves contact_inboxes when payload does not include them', () => {
      const contactInboxes = [{ source_id: 'source-1', inbox: { id: 1 } }];
      const state = {
        records: {
          1: {
            id: 1,
            name: 'contact1',
            contact_inboxes: contactInboxes,
          },
        },
      };
      mutations[types.EDIT_CONTACT](state, { id: 1, name: 'contact2' });
      expect(state.records).toEqual({
        1: { id: 1, name: 'contact2', contact_inboxes: contactInboxes },
      });
    });

    it('uses contact_inboxes from the payload when present', () => {
      const state = {
        records: {
          1: {
            id: 1,
            name: 'contact1',
            contact_inboxes: [{ source_id: 'source-1', inbox: { id: 1 } }],
          },
        },
      };
      const newContactInboxes = [{ source_id: 'source-2', inbox: { id: 2 } }];
      mutations[types.EDIT_CONTACT](state, {
        id: 1,
        name: 'contact2',
        contact_inboxes: newContactInboxes,
      });
      expect(state.records).toEqual({
        1: { id: 1, name: 'contact2', contact_inboxes: newContactInboxes },
      });
    });

    it('drops only email-channel contact_inboxes when the email changes', () => {
      const apiInbox = {
        source_id: 'uuid-api-1',
        inbox: { id: 3, channel_type: 'Channel::Api' },
      };
      const whatsappInbox = {
        source_id: '10000000000',
        inbox: { id: 2, channel_type: 'Channel::Whatsapp' },
      };
      const state = {
        records: {
          1: {
            id: 1,
            name: 'contact1',
            email: 'alice@old.com',
            phone_number: '+10000000000',
            contact_inboxes: [
              {
                source_id: 'alice@old.com',
                inbox: { id: 1, channel_type: 'Channel::Email' },
              },
              whatsappInbox,
              apiInbox,
            ],
          },
        },
      };
      mutations[types.EDIT_CONTACT](state, {
        id: 1,
        name: 'contact1',
        email: 'alice@new.com',
        phone_number: '+10000000000',
      });
      // the email-channel entry points at the stale address and is dropped;
      // phone-derived and API entries are unaffected by the email change
      expect(state.records[1].contact_inboxes).toEqual([
        whatsappInbox,
        apiInbox,
      ]);
      expect(state.records[1].email).toEqual('alice@new.com');
    });

    it('drops phone-channel contact_inboxes when the phone number changes', () => {
      const emailInbox = {
        source_id: 'alice@example.com',
        inbox: { id: 1, channel_type: 'Channel::Email' },
      };
      const state = {
        records: {
          1: {
            id: 1,
            name: 'contact1',
            email: 'alice@example.com',
            phone_number: '+10000000000',
            contact_inboxes: [
              emailInbox,
              {
                source_id: '10000000000',
                inbox: { id: 2, channel_type: 'Channel::Whatsapp' },
              },
              {
                // Twilio WhatsApp source_ids embed the phone with the `+`
                source_id: 'whatsapp:+10000000000',
                inbox: { id: 4, channel_type: 'Channel::TwilioSms' },
              },
            ],
          },
        },
      };
      mutations[types.EDIT_CONTACT](state, {
        id: 1,
        name: 'contact1',
        email: 'alice@example.com',
        phone_number: '+19999999999',
      });
      expect(state.records[1].contact_inboxes).toEqual([emailInbox]);
    });
  });

  describe('#SET_CONTACT_FILTERS', () => {
    it('set contact filter', () => {
      const appliedFilters = [
        {
          attribute_key: 'name',
          filter_operator: 'equal_to',
          values: ['fayaz'],
          query_operator: 'and',
        },
      ];
      mutations[types.SET_CONTACT_FILTERS](appliedFilters);
      expect(appliedFilters).toEqual([
        {
          attribute_key: 'name',
          filter_operator: 'equal_to',
          values: ['fayaz'],
          query_operator: 'and',
        },
      ]);
    });
  });
  describe('#CLEAR_CONTACT_FILTERS', () => {
    it('clears applied contact filters', () => {
      const state = {
        appliedFilters: [
          {
            attribute_key: 'name',
            filter_operator: 'equal_to',
            values: ['fayaz'],
            query_operator: 'and',
          },
        ],
      };
      mutations[types.CLEAR_CONTACT_FILTERS](state);
      expect(state.appliedFilters).toEqual([]);
    });
  });
});
