import { describe, expect, it, vi } from 'vitest';

import Form from '../Form.vue';

const getValidation = Form.methods.getValidation;
const initialMessageHandler = Form.watch.initialMessage.handler;
const onSubmit = Form.methods.onSubmit;

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

describe('PreChat Form initial message draft', () => {
  it('keeps the shared initial message when copying it to the visible form field', () => {
    const context = {
      formValues: {},
      hasActiveCampaign: false,
      $store: { dispatch: vi.fn() },
    };

    initialMessageHandler.call(context, 'Need help with this item');

    expect(context.formValues.message).toBe('Need help with this item');
    expect(context.$store.dispatch).not.toHaveBeenCalledWith(
      'conversation/clearInitialMessage'
    );
  });

  it('does not consume the shared initial message when campaigns hide the message field', () => {
    const context = {
      formValues: {},
      hasActiveCampaign: true,
      $store: { dispatch: vi.fn() },
    };

    initialMessageHandler.call(context, 'Need help with this item');

    expect(context.formValues.message).toBeUndefined();
    expect(context.$store.dispatch).not.toHaveBeenCalled();
  });

  it('clears the shared initial message on form submission', () => {
    const context = {
      activeCampaign: {},
      conversationCustomAttributes: {},
      contactCustomAttributes: {},
      formValues: {
        emailAddress: 'jane@example.com',
        fullName: 'Jane',
        message: 'Need help with this item',
      },
      $emit: vi.fn(),
      $store: { dispatch: vi.fn() },
    };

    onSubmit.call(context);

    expect(context.$store.dispatch).toHaveBeenCalledWith(
      'conversation/clearInitialMessage'
    );
    expect(context.$emit).toHaveBeenCalledWith(
      'submitPreChat',
      expect.objectContaining({ message: 'Need help with this item' })
    );
  });

  it('keeps the shared initial message when submitting campaign-owned pre-chat', () => {
    const context = {
      activeCampaign: { id: 1 },
      conversationCustomAttributes: {},
      contactCustomAttributes: {},
      formValues: {
        emailAddress: 'jane@example.com',
        fullName: 'Jane',
      },
      hasActiveCampaign: true,
      $emit: vi.fn(),
      $store: { dispatch: vi.fn() },
    };

    onSubmit.call(context);

    expect(context.$store.dispatch).not.toHaveBeenCalledWith(
      'conversation/clearInitialMessage'
    );
    expect(context.$emit).toHaveBeenCalledWith(
      'submitPreChat',
      expect.objectContaining({ activeCampaignId: 1 })
    );
  });
});
