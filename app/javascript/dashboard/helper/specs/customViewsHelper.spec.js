import { getAttributeInputType, getInputType } from '../customViewsHelper';

describe('customViewsHelper', () => {
  describe('#getInputType', () => {
    it('should return plain_text if key is created_at or last_activity_at and operator is days_before', () => {
      const filterTypes = [
        { attributeKey: 'created_at', inputType: 'date' },
        { attributeKey: 'last_activity_at', inputType: 'date' },
      ];
      expect(getInputType('created_at', 'days_before', filterTypes)).toEqual(
        'plain_text'
      );
      expect(
        getInputType('last_activity_at', 'days_before', filterTypes)
      ).toEqual('plain_text');
    });

    it('should return inputType if key is not created_at or last_activity_at', () => {
      const filterTypes = [
        { attributeKey: 'created_at', inputType: 'date' },
        { attributeKey: 'last_activity_at', inputType: 'date' },
        { attributeKey: 'test', inputType: 'string' },
      ];
      expect(getInputType('test', 'days_before', filterTypes)).toEqual(
        'string'
      );
    });

    it('should return undefined if key is not created_at or last_activity_at and inputType is not present', () => {
      const filterTypes = [
        { attributeKey: 'created_at', inputType: 'date' },
        { attributeKey: 'last_activity_at', inputType: 'date' },
        { attributeKey: 'test', inputType: 'string' },
      ];
      expect(getInputType('test', 'days_before', filterTypes)).toEqual(
        'string'
      );
    });
  });

  describe('#getAttributeInputType', () => {
    it('should return multi_select if attribute_display_type is checkbox or list', () => {
      const allCustomAttributes = [
        { attribute_key: 'test', attribute_display_type: 'checkbox' },
        { attribute_key: 'test2', attribute_display_type: 'list' },
      ];
      expect(getAttributeInputType('test', allCustomAttributes)).toEqual(
        'multi_select'
      );
      expect(getAttributeInputType('test2', allCustomAttributes)).toEqual(
        'multi_select'
      );
    });

    it('should return string if attribute_display_type is text, number, date or link', () => {
      const allCustomAttributes = [
        { attribute_key: 'test', attribute_display_type: 'text' },
        { attribute_key: 'test2', attribute_display_type: 'number' },
        { attribute_key: 'test3', attribute_display_type: 'date' },
        { attribute_key: 'test4', attribute_display_type: 'link' },
      ];
      expect(getAttributeInputType('test', allCustomAttributes)).toEqual(
        'string'
      );
      expect(getAttributeInputType('test2', allCustomAttributes)).toEqual(
        'string'
      );
      expect(getAttributeInputType('test3', allCustomAttributes)).toEqual(
        'string'
      );
      expect(getAttributeInputType('test4', allCustomAttributes)).toEqual(
        'string'
      );
    });
  });
});
