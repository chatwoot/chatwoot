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

    it('preserves a cached attachments list across edits', () => {
      const attachments = [{ id: 11, file_type: 'image' }];
      const state = {
        records: {
          1: { id: 1, name: 'contact1', attachments },
        },
      };
      mutations[types.EDIT_CONTACT](state, { id: 1, name: 'contact2' });
      expect(state.records[1]).toEqual({
        id: 1,
        name: 'contact2',
        attachments,
      });
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

  describe('#SET_CONTACT_ATTACHMENTS', () => {
    it('attaches the list to the existing contact record', () => {
      const state = { records: { 1: { id: 1, name: 'Sivin' } } };
      const data = [{ id: 11, file_type: 'image' }];
      mutations[types.SET_CONTACT_ATTACHMENTS](state, { id: 1, data });
      expect(state.records[1]).toEqual({
        id: 1,
        name: 'Sivin',
        attachments: data,
      });
    });

    it('creates a record shell when the contact is not yet loaded', () => {
      const state = { records: {} };
      const data = [{ id: 12, file_type: 'file' }];
      mutations[types.SET_CONTACT_ATTACHMENTS](state, { id: 5, data });
      expect(state.records[5]).toEqual({ attachments: data });
    });

    it('replaces an existing attachment list', () => {
      const state = {
        records: { 1: { id: 1, attachments: [{ id: 99 }] } },
      };
      const data = [{ id: 11 }];
      mutations[types.SET_CONTACT_ATTACHMENTS](state, { id: 1, data });
      expect(state.records[1].attachments).toEqual(data);
    });
  });
});
