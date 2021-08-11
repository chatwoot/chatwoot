import { validEmailsByComma } from '../emailHeadHelper';

describe('#validEmailsByComma', () => {
  it('returns true when empty string is passed', () => {
    expect(validEmailsByComma('')).toEqual(true);
  });
  it('returns true when valid emails separated by comma is passed', () => {
    expect(validEmailsByComma('ni@njan.com,po@va.da')).toEqual(true);
  });
  it('returns false when one of the email passed is invalid', () => {
    expect(validEmailsByComma('ni@njan.com,pova.da')).toEqual(false);
  });
});
