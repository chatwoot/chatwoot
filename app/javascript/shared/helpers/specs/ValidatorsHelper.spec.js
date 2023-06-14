import {
  shouldBeUrl,
  isPhoneNumberValidWithDialCode,
  isPhoneE164OrEmpty,
  isPhoneE164,
  startsWithPlus,
  isValidPassword,
  isPhoneNumberValid,
  isNumber,
  isDomain,
} from '../Validators';

describe('#shouldBeUrl', () => {
  it('should return correct url', () => {
    expect(shouldBeUrl('http')).toEqual(true);
  });
  it('should return wrong url', () => {
    expect(shouldBeUrl('')).toEqual(true);
    expect(shouldBeUrl('abc')).toEqual(false);
  });
});

describe('#isPhoneE164', () => {
  it('should return correct phone number', () => {
    expect(isPhoneE164('+1234567890')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneE164('1234567890')).toEqual(false);
    expect(isPhoneE164('12345678A9')).toEqual(false);
    expect(isPhoneE164('+12345678901234567890')).toEqual(false);
  });
});

describe('#isPhoneE164OrEmpty', () => {
  it('should return correct phone number', () => {
    expect(isPhoneE164OrEmpty('+1234567890')).toEqual(true);
    expect(isPhoneE164OrEmpty('')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneE164OrEmpty('1234567890')).toEqual(false);
    expect(isPhoneE164OrEmpty('12345678A9')).toEqual(false);
    expect(isPhoneE164OrEmpty('+12345678901234567890')).toEqual(false);
  });
});

describe('#isPhoneNumberValid', () => {
  it('should return correct phone number', () => {
    expect(isPhoneNumberValid('1234567890', '+91')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneNumberValid('12345A67890', '+1')).toEqual(false);
    expect(isPhoneNumberValid('12345A6789120', '+1')).toEqual(false);
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

describe('#isPhoneNumberValidWithDialCode', () => {
  it('should return correct phone number', () => {
    expect(isPhoneNumberValidWithDialCode('+123456789')).toEqual(true);
    expect(isPhoneNumberValidWithDialCode('+12345')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(isPhoneNumberValidWithDialCode('+123')).toEqual(false);
    expect(isPhoneNumberValidWithDialCode('+1234')).toEqual(false);
  });
});

describe('#startsWithPlus', () => {
  it('should return correct phone number', () => {
    expect(startsWithPlus('+123456789')).toEqual(true);
  });
  it('should return wrong phone number', () => {
    expect(startsWithPlus('123456789')).toEqual(false);
  });
});
