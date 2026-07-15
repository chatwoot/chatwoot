import Contacts from '../../contacts';
import contactList from './fixtures';

const { getters } = Contacts;

describe('#getters', () => {
  it('getContacts', () => {
    const state = {
      records: { 1: contactList[0], 3: contactList[2] },
      sortOrder: [3, 1],
    };
    expect(getters.getContacts(state)).toEqual([
      contactList[2],
      contactList[0],
    ]);
  });

  it('getContact', () => {
    const state = {
      records: { 2: contactList[1] },
    };
    expect(getters.getContact(state)(2)).toEqual(contactList[1]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isFetchingItem: true,
        isUpdating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isFetchingItem: true,
      isUpdating: false,
    });
  });
  it('getAppliedContactFilters', () => {
    const filters = [
      {
        attribute_key: 'email',
        filter_operator: 'contains',
        values: 'a',
        query_operator: null,
      },
    ];
    const state = {
      appliedFilters: filters,
    };
    expect(getters.getAppliedContactFilters(state)).toEqual(filters);
  });

  describe('getContactAttachments', () => {
    it('returns the attachments stored on the contact record', () => {
      const data = [{ id: 11, file_type: 'image' }];
      const state = { records: { 1: { id: 1, attachments: data } } };
      expect(getters.getContactAttachments(state)(1)).toEqual(data);
    });

    it('returns an empty array when the contact has no cached attachments', () => {
      const state = { records: { 1: { id: 1 } } };
      expect(getters.getContactAttachments(state)(1)).toEqual([]);
    });

    it('returns an empty array when the contact is not in the store', () => {
      const state = { records: {} };
      expect(getters.getContactAttachments(state)(99)).toEqual([]);
    });
  });
});
