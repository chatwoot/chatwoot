import { isTruthyFlag } from '../booleanFlag';

describe('#isTruthyFlag', () => {
  it('returns true for the boolean true', () => {
    expect(isTruthyFlag(true)).toBe(true);
  });

  it('returns true for the string "true"', () => {
    expect(isTruthyFlag('true')).toBe(true);
  });

  it('returns false for the boolean false', () => {
    expect(isTruthyFlag(false)).toBe(false);
  });

  it('returns false for the string "false"', () => {
    expect(isTruthyFlag('false')).toBe(false);
  });

  it('returns false for undefined', () => {
    expect(isTruthyFlag(undefined)).toBe(false);
  });
});
