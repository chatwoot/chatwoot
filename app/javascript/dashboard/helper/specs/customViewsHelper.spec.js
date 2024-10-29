import {
  getAttributeInputType,
  getInputType,
  getValuesName,
  getValuesForStatus,
  getValuesForFilter,
  generateValuesForEditCustomViews,
  generateCustomAttributesInputType,
} from '../customViewsHelper';
import advancedFilterTypes from 'dashboard/components/widgets/conversation/advancedFilterItems/index';

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

  describe('#getValuesName', () => {
    it('should return id and name if item is present', () => {
      const list = [{ id: 1, name: 'test' }];
      const idKey = 'id';
      const nameKey = 'name';
      const values = [1];
      expect(getValuesName(values, list, idKey, nameKey)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and value if item is not present', () => {
      const list = [{ id: 1, name: 'test' }];
      const idKey = 'id';
      const nameKey = 'name';
      const values = [2];
      expect(getValuesName(values, list, idKey, nameKey)).toEqual({
        id: 2,
        name: 2,
      });
    });
  });

  describe('#getValuesForStatus', () => {
    it('should return id and name if value is present', () => {
      const values = ['open'];
      expect(getValuesForStatus(values)).toEqual([
        { id: 'open', name: 'open' },
      ]);
    });

    it('should return id and name if multiple values are present', () => {
      const values = ['open', 'resolved'];
      expect(getValuesForStatus(values)).toEqual([
        { id: 'open', name: 'open' },
        { id: 'resolved', name: 'resolved' },
      ]);
    });
  });

  describe('#getValuesForFilter', () => {
    it('should return id and name if attribute_key is status', () => {
      const filter = { attribute_key: 'status', values: ['open', 'resolved'] };
      const params = {};
      expect(getValuesForFilter(filter, params)).toEqual([
        { id: 'open', name: 'open' },
        { id: 'resolved', name: 'resolved' },
      ]);
    });

    it('should return id and name if attribute_key is assignee_id', () => {
      const filter = { attribute_key: 'assignee_id', values: [1] };
      const params = { agents: [{ id: 1, name: 'test' }] };
      expect(getValuesForFilter(filter, params)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and name if attribute_key is inbox_id', () => {
      const filter = { attribute_key: 'inbox_id', values: [1] };
      const params = { inboxes: [{ id: 1, name: 'test' }] };
      expect(getValuesForFilter(filter, params)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and name if attribute_key is team_id', () => {
      const filter = { attribute_key: 'team_id', values: [1] };
      const params = { teams: [{ id: 1, name: 'test' }] };
      expect(getValuesForFilter(filter, params)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and title if attribute_key is campaign_id', () => {
      const filter = { attribute_key: 'campaign_id', values: [1] };
      const params = { campaigns: [{ id: 1, title: 'test' }] };
      expect(getValuesForFilter(filter, params)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and title if attribute_key is labels', () => {
      const filter = { attribute_key: 'labels', values: ['test'] };
      const params = { labels: [{ title: 'test' }] };
      expect(getValuesForFilter(filter, params)).toEqual([
        { id: 'test', name: 'test' },
      ]);
    });

    it('should return id and name if attribute_key is browser_language', () => {
      const filter = { attribute_key: 'browser_language', values: ['en'] };
      const params = { languages: [{ id: 'en', name: 'English' }] };
      expect(getValuesForFilter(filter, params)).toEqual([
        { id: 'en', name: 'English' },
      ]);
    });

    it('should return id and name if attribute_key is country_code', () => {
      const filter = { attribute_key: 'country_code', values: ['IN'] };
      const params = { countries: [{ id: 'IN', name: 'India' }] };
      expect(getValuesForFilter(filter, params)).toEqual([
        { id: 'IN', name: 'India' },
      ]);
    });

    it('should return id and name if attribute_key is not present', () => {
      const filter = { attribute_key: 'test', values: [1] };
      const params = {};
      expect(getValuesForFilter(filter, params)).toEqual({
        id: 1,
        name: 1,
      });
    });
  });

  describe('#generateValuesForEditCustomViews', () => {
    it('should return id and name if inboxType is multi_select or search_select', () => {
      const filter = {
        attribute_key: 'assignee_id',
        filter_operator: 'and',
        values: [1],
      };
      const params = {
        filterTypes: advancedFilterTypes,
        allCustomAttributes: [],
        agents: [{ id: 1, name: 'test' }],
      };
      expect(generateValuesForEditCustomViews(filter, params)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and name if inboxType is not multi_select or search_select', () => {
      const filter = {
        attribute_key: 'assignee_id',
        filter_operator: 'and',
        values: [1],
      };
      const params = {
        filterTypes: advancedFilterTypes,
        allCustomAttributes: [],
        agents: [{ id: 1, name: 'test' }],
      };
      expect(generateValuesForEditCustomViews(filter, params)).toEqual({
        id: 1,
        name: 'test',
      });
    });

    it('should return id and name if inboxType is undefined', () => {
      const filter = {
        attribute_key: 'test2',
        filter_operator: 'and',
        values: [1],
      };
      const params = {
        filterTypes: advancedFilterTypes,
        allCustomAttributes: [
          { attribute_key: 'test', attribute_display_type: 'checkbox' },
          { attribute_key: 'test2', attribute_display_type: 'list' },
        ],
      };
      expect(generateValuesForEditCustomViews(filter, params)).toEqual({
        id: 1,
        name: 1,
      });
    });

    it('should return value as string if filterInputTypes is string', () => {
      const filter = {
        attribute_key: 'test',
        filter_operator: 'and',
        values: [1],
      };
      const params = {
        filterTypes: advancedFilterTypes,
        allCustomAttributes: [
          { attribute_key: 'test', attribute_display_type: 'date' },
          { attribute_key: 'test2', attribute_display_type: 'list' },
        ],
      };
      expect(generateValuesForEditCustomViews(filter, params)).toEqual('1');
    });
  });

  describe('#generateCustomAttributesInputType', () => {
    it('should return string if type is text', () => {
      expect(generateCustomAttributesInputType('text')).toEqual('string');
    });

    it('should return string if type is number', () => {
      expect(generateCustomAttributesInputType('number')).toEqual('string');
    });

    it('should return string if type is date', () => {
      expect(generateCustomAttributesInputType('date')).toEqual('string');
    });

    it('should return multi_select if type is checkbox', () => {
      expect(generateCustomAttributesInputType('checkbox')).toEqual(
        'multi_select'
      );
    });

    it('should return multi_select if type is list', () => {
      expect(generateCustomAttributesInputType('list')).toEqual('multi_select');
    });

    it('should return string if type is link', () => {
      expect(generateCustomAttributesInputType('link')).toEqual('string');
    });
  });
});
