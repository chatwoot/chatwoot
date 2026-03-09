import { removeEmoji } from '../emoji';

describe('#removeEmoji', () => {
  it('returns values without emoji', () => {
    expect(removeEmoji('😄Hi👋🏻 there❕')).toEqual('Hi there');
  });
});
