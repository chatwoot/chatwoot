import { canTakeFixedValue } from './mcpTools';

describe('canTakeFixedValue', () => {
  it('allows text, numbers and true or false, which the API can convert', () => {
    ['string', 'integer', 'number', 'boolean', ['integer', 'null']].forEach(
      type => expect(canTakeFixedValue({ type })).toBe(true)
    );
  });

  it('refuses a list or an object, which a fixed text cannot fill', () => {
    ['array', 'object', ['object', 'null']].forEach(type =>
      expect(canTakeFixedValue({ type })).toBe(false)
    );
  });
});
