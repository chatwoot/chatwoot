import {
  validLabelCharacters,
  getLabelTitleErrorMessage,
} from '../validations';

describe('#validLabelCharacters', () => {
  it('validates the label', () => {
    expect(validLabelCharacters('')).toEqual(false);
    expect(validLabelCharacters('str str')).toEqual(false);
    expect(validLabelCharacters('str_str')).toEqual(true);
    expect(validLabelCharacters('str-str')).toEqual(true);
  });
});

describe('#getLabelTitleErrorMessage', () => {
  const createValidation = titleValidation => ({
    title: {
      $error: titleValidation.$error,
      required: titleValidation.required,
      minLength: titleValidation.minLength,
      validLabelCharacters: titleValidation.validLabelCharacters,
    },
  });

  it('returns an empty string when there are no validation errors', () => {
    const validation = createValidation({
      $error: false,
      required: true,
      minLength: true,
      validLabelCharacters: true,
    });

    expect(getLabelTitleErrorMessage(validation)).toEqual('');
  });

  it('returns a required error message when the title is required but not provided', () => {
    const validation = createValidation({
      $error: true,
      required: false,
      minLength: true,
      validLabelCharacters: true,
    });

    expect(getLabelTitleErrorMessage(validation)).toEqual(
      'LABEL_MGMT.FORM.NAME.REQUIRED_ERROR'
    );
  });

  it('returns a minimum length error message when the title is too short', () => {
    const validation = createValidation({
      $error: true,
      required: true,
      minLength: false,
      validLabelCharacters: true,
    });

    expect(getLabelTitleErrorMessage(validation)).toEqual(
      'LABEL_MGMT.FORM.NAME.MINIMUM_LENGTH_ERROR'
    );
  });

  it('returns a valid label characters error message when the title has invalid characters', () => {
    const validation = createValidation({
      $error: true,
      required: true,
      minLength: true,
      validLabelCharacters: false,
    });

    expect(getLabelTitleErrorMessage(validation)).toEqual(
      'LABEL_MGMT.FORM.NAME.VALID_ERROR'
    );
  });
});
