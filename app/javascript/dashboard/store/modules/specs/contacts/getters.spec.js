import { getters } from '../../contacts';
import contactList from './fixtures';

describe('#getters', () => {
  it('getContacts', () => {
    const state = {
      records: contactList,
    };
    expect(getters.getContacts(state)).toEqual(contactList);
  });

  it('getContact', () => {
    const state = {
      records: contactList,
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
