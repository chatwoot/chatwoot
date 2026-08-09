import { describe, expect, it } from 'vitest';

import Form from '../Form.vue';

const getValidation = Form.methods.getValidation;

const validationFor = (field, required) =>
  getValidation.call(
    {
      isContactFieldRequired: () => required,
    },
    field
  );

describe('PreChat Form getValidation', () => {
  it('returns accepted for a required checkbox', () => {
    expect(validationFor({ type: 'checkbox', name: 'checkbox' }, true)).toEqual(
      [['accepted']]
    );
  });

  it('returns optional for an optional checkbox', () => {
    expect(
      validationFor({ type: 'checkbox', name: 'checkbox' }, false)
    ).toEqual([['optional']]);
  });

  it('returns required for a required text field', () => {
    expect(validationFor({ type: 'text', name: 'text' }, true)).toEqual([
      ['required'],
    ]);
  });

  it('combines required and type-specific validation rules', () => {
    expect(
      validationFor({ type: 'email', name: 'emailAddress' }, true)
    ).toEqual([['required'], ['email']]);
  });
});
