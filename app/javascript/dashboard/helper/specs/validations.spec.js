import { describe, it, expect } from 'vitest';
import {
  validateConversationOrContactFilters,
  validateAutomation,
} from '../validations';

describe('validateConversationOrContactFilters', () => {
  it('should return no errors for valid filters', () => {
    const validFilters = [
      { attribute_key: 'name', filter_operator: 'contains', values: 'John' },
      { attribute_key: 'email', filter_operator: 'is_present' },
    ];
    const errors = validateConversationOrContactFilters(validFilters);
    expect(errors).toEqual({});
  });

  it('should return errors for invalid filters', () => {
    const invalidFilters = [
      { attribute_key: '', filter_operator: 'contains', values: 'John' },
      { attribute_key: 'email', filter_operator: '' },
      { attribute_key: 'age', filter_operator: 'equals' },
    ];
    const errors = validateConversationOrContactFilters(invalidFilters);
    expect(errors).toEqual({
      filter_0: 'ATTRIBUTE_KEY_REQUIRED',
      filter_1: 'FILTER_OPERATOR_REQUIRED',
      filter_2: 'VALUE_REQUIRED',
    });
  });

  it('should validate days_before operator correctly', () => {
    const filters = [
      { attribute_key: 'date', filter_operator: 'days_before', values: '0' },
      { attribute_key: 'date', filter_operator: 'days_before', values: '999' },
      { attribute_key: 'date', filter_operator: 'days_before', values: '500' },
    ];
    const errors = validateConversationOrContactFilters(filters);
    expect(errors).toEqual({
      filter_0: 'VALUE_MUST_BE_BETWEEN_1_AND_998',
      filter_1: 'VALUE_MUST_BE_BETWEEN_1_AND_998',
    });
  });
});

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
});
