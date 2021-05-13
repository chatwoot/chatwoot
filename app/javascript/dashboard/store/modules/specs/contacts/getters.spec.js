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
});
