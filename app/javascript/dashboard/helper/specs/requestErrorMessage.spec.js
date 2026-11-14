import {
  CONTACT_FIELD_LABELS,
  requestErrorMessage,
} from '../requestErrorMessage';

const t = (key, params) => (params ? `${key}|${JSON.stringify(params)}` : key);
const FALLBACK = 'FLOW.TRY_LATER';

const rejected = (status, data) => ({ response: { status, data } });

describe('requestErrorMessage', () => {
  it('names the field and the error type from the details', () => {
    const error = rejected(422, {
      message: 'Email has already been taken',
      attributes: ['email'],
      details: { email: [{ error: 'taken', value: 'a@b.c' }] },
    });

    expect(requestErrorMessage(error, t, FALLBACK, CONTACT_FIELD_LABELS)).toBe(
      'REQUEST_ERRORS.FIELD.TAKEN|{"field":"CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL"}'
    );
  });

  it('tells a format error apart from a duplicate', () => {
    const error = rejected(422, {
      attributes: ['phone_number'],
      details: { phone_number: [{ error: 'invalid', value: '123' }] },
    });

    expect(requestErrorMessage(error, t, FALLBACK, CONTACT_FIELD_LABELS)).toBe(
      'REQUEST_ERRORS.FIELD.INVALID|{"field":"CONTACT_FORM.FORM.PHONE_NUMBER.LABEL"}'
    );
  });

  it('falls back to the attribute list when details are absent', () => {
    const error = rejected(422, { attributes: ['email'] });

    expect(requestErrorMessage(error, t, FALLBACK, CONTACT_FIELD_LABELS)).toBe(
      'REQUEST_ERRORS.FIELD.OTHER|{"field":"CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL"}'
    );
  });

  it('uses a typed message without a field the form does not label', () => {
    const error = rejected(422, {
      attributes: ['custom_attributes'],
      details: { custom_attributes: [{ error: 'too_long' }] },
    });

    expect(requestErrorMessage(error, t, FALLBACK, CONTACT_FIELD_LABELS)).toBe(
      'REQUEST_ERRORS.GENERIC.TOO_LONG'
    );
  });

  it('maps a custom error type to the generic message, never the server text', () => {
    const error = rejected(422, {
      message: 'Inbox is not a website inbox',
      attributes: ['base'],
      details: { base: [{ error: 'Inbox is not a website inbox' }] },
    });

    expect(requestErrorMessage(error, t, FALLBACK)).toBe(
      'REQUEST_ERRORS.GENERIC.OTHER'
    );
  });

  it.each([
    ['a 5xx', rejected(500, { error: 'boom' })],
    ['a request without an answer', new Error('Network Error')],
    ['a 4xx that is not a validation error', rejected(404, { error: 'nope' })],
  ])('keeps the flow fallback for %s', (_, error) => {
    expect(requestErrorMessage(error, t, FALLBACK, CONTACT_FIELD_LABELS)).toBe(
      FALLBACK
    );
  });
});
