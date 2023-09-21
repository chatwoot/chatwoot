import { sanitizeLabel } from '../sanitizeData';

describe('sanitizeLabel', () => {
  it('should return an empty string when given an empty string', () => {
    const label = '';
    const sanitizedLabel = sanitizeLabel(label);
    expect(sanitizedLabel).toEqual('');
  });

  it('should remove leading and trailing whitespace', () => {
    const label = '  My Label  ';
    const sanitizedLabel = sanitizeLabel(label);
    expect(sanitizedLabel).toEqual('my-label');
  });

  it('should convert all characters to lowercase', () => {
    const label = 'My Label';
    const sanitizedLabel = sanitizeLabel(label);
    expect(sanitizedLabel).toEqual('my-label');
  });

  it('should replace spaces with hyphens', () => {
    const label = 'My Label 123';
    const sanitizedLabel = sanitizeLabel(label);
    expect(sanitizedLabel).toEqual('my-label-123');
  });

  it('should remove any characters that are not alphanumeric, underscore, or hyphen', () => {
    const label = 'My_Label!123';
    const sanitizedLabel = sanitizeLabel(label);
    expect(sanitizedLabel).toEqual('my_label123');
  });

  it('should handle null and undefined input', () => {
    const nullLabel = null;
    const undefinedLabel = undefined;

    // @ts-ignore - intentionally passing null and undefined to test
    const sanitizedNullLabel = sanitizeLabel(nullLabel);
    const sanitizedUndefinedLabel = sanitizeLabel(undefinedLabel);
    expect(sanitizedNullLabel).toEqual('');
    expect(sanitizedUndefinedLabel).toEqual('');
  });
});
