import { describe, it, expect } from 'vitest';
import {
  validateConversationOrContactFilters,
  // validateAutomation,
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
      filter_0: 'Attribute key is required',
      filter_1: 'Filter operator is required',
      filter_2: 'Value is required',
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
      filter_0: 'Value must be between 1 and 998',
      filter_1: 'Value must be between 1 and 998',
    });
  });
});
