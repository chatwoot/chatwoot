import { DuplicateContactException } from '../CustomErrors';

describe('DuplicateContactException', () => {
  it('returns correct exception', () => {
    const exception = new DuplicateContactException({
      attributes: ['email'],
    });
    expect(exception.message).toEqual('DUPLICATE_CONTACT');
    expect(exception.data).toEqual({
      attributes: ['email'],
    });
  });
});
