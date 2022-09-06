import { getLanguageName } from '../languages';

describe('#getLanguageName', () => {
  it('Returns correct language name', () => {
    expect(getLanguageName('es')).toEqual('Spanish');
    expect(getLanguageName()).toEqual('');
    expect(getLanguageName('rrr')).toEqual('');
    expect(getLanguageName('')).toEqual('');
  });
});
