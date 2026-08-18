import { describe, it, expect } from 'vitest';
import { validateAutomation } from '../validations';

describe('validateAutomation', () => {
  it('should return no errors for a valid automation', () => {
    const validAutomation = {
      name: 'Test Automation',
      description: 'A test automation',
      event_name: 'message_created',
      conditions: [
        {
          attribute_key: 'content',
          filter_operator: 'contains',
          values: 'hello',
        },
      ],
      actions: [
        { action_name: 'send_message', action_params: ['Hello there!'] },
      ],
    };
    const errors = validateAutomation(validAutomation);
    expect(errors).toEqual({});
  });

  it('should return errors for missing basic fields', () => {
    const invalidAutomation = {
      name: '',
      description: '',
      event_name: '',
      conditions: [],
      actions: [],
    };
    const errors = validateAutomation(invalidAutomation);
    expect(errors).toHaveProperty('name');
    expect(errors).toHaveProperty('description');
    expect(errors).toHaveProperty('event_name');
  });

  it('should return errors for invalid conditions', () => {
    const automationWithInvalidConditions = {
      name: 'Test',
      description: 'Test',
      event_name: 'message_created',
      conditions: [{ attribute_key: '', filter_operator: '', values: '' }],
      actions: [{ action_name: 'send_message', action_params: ['Hello'] }],
    };
    const errors = validateAutomation(automationWithInvalidConditions);
    expect(errors).toHaveProperty('condition_0');
  });

  it('should return errors for invalid actions', () => {
    const automationWithInvalidActions = {
      name: 'Test',
      description: 'Test',
      event_name: 'message_created',
      conditions: [
        {
          attribute_key: 'content',
          filter_operator: 'contains',
          values: 'hello',
        },
      ],
      actions: [{ action_name: 'send_message', action_params: [] }],
    };
    const errors = validateAutomation(automationWithInvalidActions);
    expect(errors).toHaveProperty('action_0');
  });

  it('should not require action params for specific actions', () => {
    const automationWithNoParamAction = {
      name: 'Test',
      description: 'Test',
      event_name: 'message_created',
      conditions: [
        {
          attribute_key: 'content',
          filter_operator: 'contains',
          values: 'hello',
        },
      ],
      actions: [{ action_name: 'mute_conversation' }],
    };
    const errors = validateAutomation(automationWithNoParamAction);
    expect(errors).toEqual({});
  });

  it('requires inbox and template for send_whatsapp_template', () => {
    const base = {
      name: 'Test',
      description: 'Test',
      event_name: 'message_created',
      conditions: [
        {
          attribute_key: 'content',
          filter_operator: 'contains',
          values: 'hello',
        },
      ],
    };
    const missing = validateAutomation({
      ...base,
      actions: [{ action_name: 'send_whatsapp_template', action_params: {} }],
    });
    expect(missing).toHaveProperty('action_0');

    const valid = validateAutomation({
      ...base,
      actions: [
        {
          action_name: 'send_whatsapp_template',
          action_params: {
            inbox_id: 12,
            name: 'hello',
            language: 'es',
          },
        },
      ],
    });
    expect(valid).toEqual({});
  });

  it('allows on-date time schedule without days', () => {
    const errors = validateAutomation({
      name: 'Test',
      description: 'Test',
      event_name: 'time_triggered',
      conditions: [],
      actions: [{ action_name: 'add_label', action_params: ['follow-up'] }],
      schedule: {
        kind: 'days_since_attribute',
        attribute_key: 'fecha_cita',
        relative_to: 'on',
      },
    });
    expect(errors).toEqual({});
  });

  it('requires days for after and before time schedules', () => {
    const base = {
      name: 'Test',
      description: 'Test',
      event_name: 'time_triggered',
      conditions: [],
      actions: [{ action_name: 'add_label', action_params: ['follow-up'] }],
    };
    const missingDays = validateAutomation({
      ...base,
      schedule: {
        kind: 'days_since_attribute',
        attribute_key: 'fecha_cita',
        relative_to: 'before',
      },
    });
    expect(missingDays).toHaveProperty('schedule');

    const validBefore = validateAutomation({
      ...base,
      schedule: {
        kind: 'days_since_attribute',
        attribute_key: 'fecha_cita',
        relative_to: 'before',
        days: 3,
      },
    });
    expect(validBefore).toEqual({});
  });
});
