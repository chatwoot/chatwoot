import { validateForm } from '../src/utils/validation';

describe('validateForm', () => {
  it('should return true when all required checkboxes are checked', () => {
    const formState = {};
    const checkboxAttributes = [
      { name: 'terms', required: true, value: true },
      { name: 'newsletter', required: false, value: false }
    ];
    expect(validateForm(formState, checkboxAttributes)).toBe(true);
  });

  it('should return false when a required checkbox is not checked', () => {
    const formState = {};
    const checkboxAttributes = [
      { name: 'terms', required: true, value: false },
      { name: 'newsletter', required: false, value: true }
    ];
    expect(validateForm(formState, checkboxAttributes)).toBe(false);
  });

  it('should return true when no checkboxes are required', () => {
    const formState = {};
    const checkboxAttributes = [
      { name: 'newsletter', required: false, value: false }
    ];
    expect(validateForm(formState, checkboxAttributes)).toBe(true);
  });

  it('should handle an empty checkboxAttributes array', () => {
    const formState = {};
    const checkboxAttributes = [];
    expect(validateForm(formState, checkboxAttributes)).toBe(true);
  });

  it('should handle unexpected input gracefully', () => {
    const formState = {};
    const checkboxAttributes = null;
    expect(() => validateForm(formState, checkboxAttributes)).not.toThrow();
    expect(validateForm(formState, checkboxAttributes)).toBe(true);
  });
});