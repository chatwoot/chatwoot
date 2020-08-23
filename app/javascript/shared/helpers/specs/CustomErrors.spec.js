const { DuplicateContactException } = require('../CustomErrors');

describe('DuplicateContactException', () => {
  it('returns correct exception', () => {
    const exception = new DuplicateContactException({
      id: 1,
      name: 'contact-name',
      email: 'email@example.com',
    });
    expect(exception.message).toEqual('DUPLICATE_CONTACT');
    expect(exception.data).toEqual({
      id: 1,
      name: 'contact-name',
      email: 'email@example.com',
    });
  });
});
