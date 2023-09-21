import { validLabelCharacters } from '../validations';

describe('#validLabelCharacters', () => {
  it('validates the label', () => {
    expect(validLabelCharacters('')).toEqual(false);
    expect(validLabelCharacters('str str')).toEqual(false);
    expect(validLabelCharacters('str_str')).toEqual(true);
    expect(validLabelCharacters('str-str')).toEqual(true);
  });
});
