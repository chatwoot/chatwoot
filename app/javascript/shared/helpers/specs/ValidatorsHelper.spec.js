import { shouldBeUrl } from '../Validators';
import { isValidPassword } from '../Validators';
import { isNumber } from '../Validators';
import { isDomain } from '../Validators';

describe('#shouldBeUrl', () => {
  it('should return correct url', () => {
    expect(shouldBeUrl('http')).toEqual(true);
  });
});

describe('#isValidPassword', () => {
  it('should return correct password', () => {
    expect(isValidPassword('testPass4!')).toEqual(true);
    expect(isValidPassword('testPass4-')).toEqual(true);
    expect(isValidPassword('testPass4\\')).toEqual(true);
    expect(isValidPassword("testPass4'")).toEqual(true);
  });

  it('should return wrong password', () => {
    expect(isValidPassword('testpass4')).toEqual(false);
    expect(isValidPassword('testPass4')).toEqual(false);
    expect(isValidPassword('testpass4!')).toEqual(false);
    expect(isValidPassword('testPass!')).toEqual(false);
  });
});

describe('#isNumber', () => {
  it('should return correct number', () => {
    expect(isNumber('123')).toEqual(true);
  });

  it('should return wrong number', () => {
    expect(isNumber('123-')).toEqual(false);
    expect(isNumber('123./')).toEqual(false);
    expect(isNumber('string')).toEqual(false);
  });
});

describe('#isDomain', () => {
  it('should return correct domain', () => {
    expect(isDomain('test.com')).toEqual(true);
    expect(isDomain('www.test.com')).toEqual(true);
  });

  it('should return wrong domain', () => {
    expect(isDomain('test')).toEqual(false);
    expect(isDomain('test.')).toEqual(false);
    expect(isDomain('test.123')).toEqual(false);
    expect(isDomain('http://www.test.com')).toEqual(false);
    expect(isDomain('https://test.in')).toEqual(false);
  });
});
