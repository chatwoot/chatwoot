import { isTruthyFlag } from '../booleanFlag';

describe('#isTruthyFlag', () => {
  it.each([true, 'true', 1, '1', 't', 'T', 'on', 'ON', 'yes'])(
    'returns true for %p, matching ActiveModel::Type::Boolean',
    value => {
      expect(isTruthyFlag(value)).toBe(true);
    }
  );

  it.each([false, 'false', 'FALSE', 0, '0', 'f', 'F', 'off', 'OFF'])(
    'returns false for %p, matching ActiveModel::Type::Boolean::FALSE_VALUES',
    value => {
      expect(isTruthyFlag(value)).toBe(false);
    }
  );

  it.each([null, undefined, ''])('returns false for %p', value => {
    expect(isTruthyFlag(value)).toBe(false);
  });
});
