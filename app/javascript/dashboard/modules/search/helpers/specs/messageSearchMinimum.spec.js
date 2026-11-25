import { isBelowMessageSearchMinimum } from '../messageSearchMinimum';

// The dashboard must decide like SearchService, which uses Ruby's String#strip and #length.
describe('isBelowMessageSearchMinimum', () => {
  it('counts a supplementary character as one, like Ruby', () => {
    expect(isBelowMessageSearchMinimum('👍a', 3)).toBe(true);
    expect(isBelowMessageSearchMinimum('👍ab', 3)).toBe(false);
  });

  it('keeps a non-breaking space, which Ruby strip does not remove', () => {
    expect(isBelowMessageSearchMinimum('16 ', 3)).toBe(false);
  });

  it('strips the ASCII whitespace Ruby strip removes', () => {
    expect(isBelowMessageSearchMinimum('\t16 \n', 3)).toBe(true);
  });
});
