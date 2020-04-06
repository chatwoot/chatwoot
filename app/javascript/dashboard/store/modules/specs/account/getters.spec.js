import { getters } from '../../accounts';

const accountData = {
  id: 1,
  name: 'Company one',
  locale: 'en',
};

describe('#getters', () => {
  it('getAccount', () => {
    const state = {
      records: [accountData],
    };
    expect(getters.getAccount(state)(1)).toEqual(accountData);
  });
});
