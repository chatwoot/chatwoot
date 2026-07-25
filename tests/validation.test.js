const validateForm = require('../src/utils/validation');

describe('validateForm', () => {
  test('should return true for valid form data with all required fields filled', () => {
    const formData = {
      name: { required: true, value: 'John Doe' },
      email: { required: true, value: 'john@example.com' },
      subscribe: { required: false, value: false }
    };
    expect(validateForm(formData)).toBe(true);
  });

  test('should return false for form data with a missing required field', () => {
    const formData = {
      name: { required: true, value: '' },
      email: { required: true, value: 'john@example.com' }
    };
    expect(validateForm(formData)).toBe(false);
  });

  test('should return false for form data with a required checkbox unchecked', () => {
    const formData = {
      terms: { required: true, type: 'checkbox', value: false },
      email: { required: true, value: 'john@example.com' }
    };
    expect(validateForm(formData)).toBe(false);
  });

  test('should return true for form data with a required checkbox checked', () => {
    const formData = {
      terms: { required: true, type: 'checkbox', value: true },
      email: { required: true, value: 'john@example.com' }
    };
    expect(validateForm(formData)).toBe(true);
  });

  test('should return true for form data with no required fields', () => {
    const formData = {
      newsletter: { required: false, value: false },
      updates: { required: false, value: true }
    };
    expect(validateForm(formData)).toBe(true);
  });

  test('should handle unexpected field types gracefully', () => {
    const formData = {
      unknownField: { required: true, type: 'unknown', value: 'some value' }
    };
    expect(validateForm(formData)).toBe(true);
  });
});