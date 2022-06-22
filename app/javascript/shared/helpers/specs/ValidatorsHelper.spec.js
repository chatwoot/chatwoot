import { shouldBeUrl } from '../Validators';
import { isValidPassword } from '../Validators';
import { isValidEmail } from '../Validators';

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

describe('isValidEmail', () => {
  it('should return correct email', () => {
    expect(isValidEmail('test@mail.com')).toEqual(true);
    expect(isValidEmail('test@chatwoot.co')).toEqual(true);
  });

  it('should return wrong email', () => {
    expect(isValidEmail('test@mail')).toEqual(false);
    expect(isValidEmail('test@mail.')).toEqual(false);
    expect(isValidEmail('test@mail.c')).toEqual(false);
    expect(isValidEmail('.test@mail.c0')).toEqual(false);
  });
});
