import { getLanguageName, getLanguageDirection } from '../languages';

describe('#getLanguageName', () => {
  it('Returns correct language name', () => {
    expect(getLanguageName('es')).toEqual('Spanish');
    expect(getLanguageName()).toEqual('');
    expect(getLanguageName('rrr')).toEqual('');
    expect(getLanguageName('')).toEqual('');
  });
});

describe('#getLanguageDirection', () => {
  it('Returns correct language direction', () => {
    expect(getLanguageDirection('es')).toEqual(false);
    expect(getLanguageDirection('ar')).toEqual(true);
  });
});
