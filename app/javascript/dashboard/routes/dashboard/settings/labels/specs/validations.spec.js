import { validLabelCharacters, notEmptyInput } from '../validations';

describe('#validLabelCharacters', () => {
  it('validates the label', () => {
    expect(validLabelCharacters('str str')).toEqual(false);
    expect(validLabelCharacters('str_str')).toEqual(true);
    expect(validLabelCharacters('str-str')).toEqual(true);
  });
});

describe('#notEmptyInput', () => {
  it('verifies if the imput is empty or not', () => {
    expect(notEmptyInput('')).toEqual(false);
    expect(notEmptyInput('str_str')).toEqual(true);
  });
});
