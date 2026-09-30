import { describe, it, expect } from 'vitest';
import {
  parseRouteFilters,
  validateAutomation,
  validateSingleFilter,
} from '../validations';

describe('validateSingleFilter', () => {
  it.each([0, false])('accepts the explicit value %s', values => {
    expect(
      validateSingleFilter({
        attribute_key: 'custom_value',
        filter_operator: 'equal_to',
        values,
      })
    ).toBeNull();
  });

  it.each([undefined, null, '', [], {}])(
    'rejects an empty value %s',
    values => {
      expect(
        validateSingleFilter({
          attribute_key: 'custom_value',
          filter_operator: 'equal_to',
          values,
        })
      ).toBe('VALUE_REQUIRED');
    }
  );

  it('still rejects zero days before', () => {
    expect(
      validateSingleFilter({
        attribute_key: 'created_at',
        filter_operator: 'days_before',
        values: 0,
      })
    ).toBe('VALUE_MUST_BE_BETWEEN_1_AND_998');
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

describe('parseRouteFilters', () => {
  const condition = {
    attribute_key: 'created_at',
    filter_operator: 'is_greater_than',
    values: '2026-09-13',
    query_operator: 'and',
  };

  it('returns the conditions for a valid list', () => {
    expect(parseRouteFilters(JSON.stringify([condition]))).toEqual([condition]);
  });

  it('accepts operators that take no value', () => {
    const presence = {
      attribute_key: 'assignee_id',
      filter_operator: 'is_present',
      values: [],
    };

    expect(parseRouteFilters(JSON.stringify([presence]))).toEqual([presence]);
  });

  it.each([
    ['undefined', undefined],
    ['empty string', ''],
    ['truncated JSON', '[{"attribute_key":"created_at'],
    ['an object', '{"attribute_key":"created_at"}'],
    ['an empty list', '[]'],
    ['a null element', '[null]'],
    ['a primitive element', '[1]'],
    ['a condition without an operator', '[{"attribute_key":"created_at"}]'],
    [
      'a condition without a value',
      '[{"attribute_key":"created_at","filter_operator":"is_greater_than"}]',
    ],
  ])('returns null for %s', (_, value) => {
    expect(parseRouteFilters(value)).toBeNull();
  });
});
