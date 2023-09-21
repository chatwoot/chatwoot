import { isASubmittedFormMessage, isAFormMessage } from '../MessageTypeHelper';

describe('#isASubmittedFormMessage', () => {
  it('should return correct value', () => {
    expect(
      isASubmittedFormMessage({
        content_type: 'form',
        content_attributes: {
          submitted_values: [{ name: 'text', value: 'Text ' }],
        },
      })
    ).toEqual(true);
  });
});

describe('#isAFormMessage', () => {
  it('should return correct value', () => {
    expect(
      isAFormMessage({
        content_type: 'form',
      })
    ).toEqual(true);
  });
});
