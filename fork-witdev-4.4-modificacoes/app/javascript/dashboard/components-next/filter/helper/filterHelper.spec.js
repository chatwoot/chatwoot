import {
  getCustomAttributeInputType,
  buildAttributesFilterTypes,
  replaceUnderscoreWithSpace,
} from './filterHelper';

describe('filterHelper', () => {
  describe('getCustomAttributeInputType', () => {
    it('returns date for date type', () => {
      expect(getCustomAttributeInputType('date')).toBe('date');
    });

    it('returns plainText for text type', () => {
      expect(getCustomAttributeInputType('text')).toBe('plainText');
    });

    it('returns searchSelect for list type', () => {
      expect(getCustomAttributeInputType('list')).toBe('searchSelect');
    });

    it('returns booleanSelect for checkbox type', () => {
      expect(getCustomAttributeInputType('checkbox')).toBe('booleanSelect');
    });

    it('returns plainText for unknown type', () => {
      expect(getCustomAttributeInputType('unknown')).toBe('plainText');
    });
  });

  describe('buildAttributesFilterTypes', () => {
    const mockGetOperatorTypes = type => {
      return type === 'list' ? ['is', 'is_not'] : ['contains', 'not_contains'];
    };

    it('builds filter types for text attributes', () => {
      const attributes = [
        {
          attributeKey: 'test_key',
          attributeDisplayName: 'Test Name',
          attributeDisplayType: 'text',
          attributeValues: [],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toEqual([
        {
          attributeKey: 'test_key',
          value: 'test_key',
          attributeName: 'Test Name',
          label: 'Test Name',
          inputType: 'plainText',
          filterOperators: ['contains', 'not_contains'],
          options: [],
          attributeModel: 'customAttributes',
        },
      ]);
    });

    it('builds filter types for list attributes with options', () => {
      const attributes = [
        {
          attributeKey: 'list_key',
          attributeDisplayName: 'List Name',
          attributeDisplayType: 'list',
          attributeValues: ['option1', 'option2'],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toEqual([
        {
          attributeKey: 'list_key',
          value: 'list_key',
          attributeName: 'List Name',
          label: 'List Name',
          inputType: 'searchSelect',
          filterOperators: ['is', 'is_not'],
          options: [
            { id: 'option1', name: 'option1' },
            { id: 'option2', name: 'option2' },
          ],
          attributeModel: 'customAttributes',
        },
      ]);
    });

    it('handles multiple attributes', () => {
      const attributes = [
        {
          attributeKey: 'date_key',
          attributeDisplayName: 'Date Name',
          attributeDisplayType: 'date',
          attributeValues: [],
        },
        {
          attributeKey: 'checkbox_key',
          attributeDisplayName: 'Checkbox Name',
          attributeDisplayType: 'checkbox',
          attributeValues: [],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toHaveLength(2);
      expect(result[0].inputType).toBe('date');
      expect(result[1].inputType).toBe('booleanSelect');
    });

    it('handles empty attributes array', () => {
      const result = buildAttributesFilterTypes([], mockGetOperatorTypes);
      expect(result).toEqual([]);
    });
  });

  describe('replaceUnderscoreWithSpace', () => {
    it('replaces underscores with spaces', () => {
      expect(replaceUnderscoreWithSpace('test_key')).toBe('test key');
    });

    it('returns empty string if input is null', () => {
      expect(replaceUnderscoreWithSpace(null)).toBe('');
    });
  });
});
