import { userInitial } from '../CommonHelper';

describe('#userInitial', () => {
  it('returns the initials of the user', () => {
    expect(userInitial('John Doe')).toEqual('JD');
    expect(userInitial('John')).toEqual('J');
    expect(userInitial('John-Doe')).toEqual('JD');
    expect(userInitial('John Doe Smith')).toEqual('JD');
  });
});
