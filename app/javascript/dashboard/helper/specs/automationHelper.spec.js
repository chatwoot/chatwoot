import * as automationHelper from '../automationHelper';
import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from 'dashboard/routes/dashboard/settings/automation/operators';

describe('automationHelper', () => {
  describe('getCustomAttributeInputType', () => {
    it('returns correct input type for known keys', () => {
      expect(automationHelper.getCustomAttributeInputType('date')).toBe('date');
      expect(automationHelper.getCustomAttributeInputType('text')).toBe(
        'plain_text'
      );
      expect(automationHelper.getCustomAttributeInputType('list')).toBe(
        'search_select'
      );
      expect(automationHelper.getCustomAttributeInputType('checkbox')).toBe(
        'search_select'
      );
    });

    it('returns plain_text for unknown keys', () => {
      expect(automationHelper.getCustomAttributeInputType('unknown')).toBe(
        'plain_text'
      );
    });
  });

  describe('isACustomAttribute', () => {
    const customAttributes = [
      { attribute_key: 'test_key' },
      { attribute_key: 'another_key' },
    ];

    it('returns true if custom attribute exists', () => {
      expect(
        automationHelper.isACustomAttribute(customAttributes, 'test_key')
      ).toBeTruthy();
    });

    it('returns undefined if custom attribute does not exist', () => {
      expect(
        automationHelper.isACustomAttribute(customAttributes, 'non_existent')
      ).toBeUndefined();
    });
  });

  describe('getCustomAttributeListDropdownValues', () => {
    const customAttributes = [
      {
        attribute_key: 'test_list',
        attribute_values: ['value1', 'value2'],
      },
    ];

    it('returns formatted dropdown values', () => {
      const result = automationHelper.getCustomAttributeListDropdownValues(
        customAttributes,
        'test_list'
      );
      expect(result).toEqual([
        { id: 'value1', name: 'value1' },
        { id: 'value2', name: 'value2' },
      ]);
    });
  });

  describe('getOperatorTypes', () => {
    it('returns correct operator types for known keys', () => {
      expect(automationHelper.getOperatorTypes('list')).toBe(OPERATOR_TYPES_1);
      expect(automationHelper.getOperatorTypes('text')).toBe(OPERATOR_TYPES_3);
      expect(automationHelper.getOperatorTypes('date')).toBe(OPERATOR_TYPES_4);
    });

    it('returns OPERATOR_TYPES_1 for unknown keys', () => {
      expect(automationHelper.getOperatorTypes('unknown')).toBe(
        OPERATOR_TYPES_1
      );
    });
  });

  describe('generateCustomAttributeTypes', () => {
    const customAttributes = [
      {
        attribute_key: 'test',
        attribute_display_name: 'Test Attribute',
        attribute_display_type: 'text',
      },
    ];

    it('generates custom attribute types correctly', () => {
      const result = automationHelper.generateCustomAttributeTypes(
        customAttributes,
        'conversation'
      );
      expect(result).toEqual([
        {
          key: 'test',
          name: 'Test Attribute',
          inputType: 'plain_text',
          filterOperators: OPERATOR_TYPES_3,
          customAttributeType: 'conversation',
        },
      ]);
    });
  });

  describe('addNoneToList', () => {
    it('adds None option to the list', () => {
      const agents = [{ id: 1, name: 'Agent 1' }];
      const result = automationHelper.addNoneToList(agents);
      expect(result).toEqual([
        { id: 'nil', name: 'None' },
        { id: 1, name: 'Agent 1' },
      ]);
    });
  });

  describe('getActionOptions', () => {
    const mockData = {
      agents: [{ id: 1, name: 'Agent 1' }],
      teams: [{ id: 1, name: 'Team 1' }],
      labels: [{ id: 1, title: 'Label 1' }],
      slaPolicies: [{ id: 1, name: 'SLA 1' }],
    };

    it('returns correct options for assign_agent', () => {
      const result = automationHelper.getActionOptions({
        ...mockData,
        type: 'assign_agent',
      });
      expect(result).toEqual([
        { id: 'nil', name: 'None' },
        { id: 1, name: 'Agent 1' },
      ]);
    });

    it('returns correct options for add_label', () => {
      const result = automationHelper.getActionOptions({
        ...mockData,
        type: 'add_label',
      });
      expect(result).toEqual([{ id: 'Label 1', name: 'Label 1' }]);
    });
  });

  describe('getConditionOptions', () => {
    const mockData = {
      agents: [{ id: 1, name: 'Agent 1' }],
      booleanFilterOptions: [
        { id: true, name: 'True' },
        { id: false, name: 'False' },
      ],
      campaigns: [{ id: 1, title: 'Campaign 1' }],
      contacts: [{ id: 1, name: 'Contact 1' }],
      countries: [{ id: 'US', name: 'United States' }],
      customAttributes: [],
      inboxes: [{ id: 1, name: 'Inbox 1' }],
      languages: [{ id: 'en', name: 'English' }],
      statusFilterOptions: [{ id: 'open', name: 'Open' }],
      teams: [{ id: 1, name: 'Team 1' }],
    };

    it('returns correct options for status', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'status',
      });
      expect(result).toEqual([{ id: 'open', name: 'Open' }]);
    });

    it('returns correct options for assignee_id', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'assignee_id',
      });
      expect(result).toEqual([{ id: 1, name: 'Agent 1' }]);
    });

    it('returns correct options for inbox_id', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'inbox_id',
      });
      expect(result).toEqual([{ id: 1, name: 'Inbox 1' }]);
    });

    it('returns correct options for team_id', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'team_id',
      });
      expect(result).toEqual([{ id: 1, name: 'Team 1' }]);
    });

    it('returns correct options for campaigns', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'campaigns',
      });
      expect(result).toEqual([{ id: 1, name: 'Campaign 1' }]);
    });

    it('returns correct options for browser_language', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'browser_language',
      });
      expect(result).toEqual([{ id: 'en', name: 'English' }]);
    });

    it('returns correct options for country_code', () => {
      const result = automationHelper.getConditionOptions({
        ...mockData,
        type: 'country_code',
      });
      expect(result).toEqual([{ id: 'US', name: 'United States' }]);
    });

    it('returns boolean options for custom checkbox attribute', () => {
      const customAttributes = [
        { attribute_key: 'is_vip', attribute_display_type: 'checkbox' },
      ];
      const result = automationHelper.getConditionOptions({
        ...mockData,
        customAttributes,
        type: 'is_vip',
      });
      expect(result).toEqual([
        { id: true, name: 'True' },
        { id: false, name: 'False' },
      ]);
    });

    it('returns list options for custom list attribute', () => {
      const customAttributes = [
        {
          attribute_key: 'product',
          attribute_display_type: 'list',
          attribute_values: ['Product A', 'Product B'],
        },
      ];
      const result = automationHelper.getConditionOptions({
        ...mockData,
        customAttributes,
        type: 'product',
      });
      expect(result).toEqual([
        { id: 'Product A', name: 'Product A' },
        { id: 'Product B', name: 'Product B' },
      ]);
    });
  });

  describe('getDefaultConditions', () => {
    it('returns correct default condition for message_created', () => {
      const result = automationHelper.getDefaultConditions('message_created');
      expect(result[0].attribute_key).toBe('message_type');
    });

    it('returns correct default condition for conversation_opened', () => {
      const result = automationHelper.getDefaultConditions(
        'conversation_opened'
      );
      expect(result[0].attribute_key).toBe('browser_language');
    });

    it('returns status condition for other event types', () => {
      const result = automationHelper.getDefaultConditions('other_event');
      expect(result[0].attribute_key).toBe('status');
    });
  });

  describe('getDefaultActions', () => {
    it('returns default action', () => {
      const result = automationHelper.getDefaultActions();
      expect(result).toEqual([
        {
          action_name: 'assign_agent',
          action_params: [],
        },
      ]);
    });
  });

  describe('getAttributes', () => {
    it('returns conditions for the given key', () => {
      const automationTypes = {
        message_created: {
          conditions: [{ key: 'message_type' }, { key: 'content' }],
        },
      };
      const result = automationHelper.getAttributes(
        automationTypes,
        'message_created'
      );
      expect(result).toEqual([{ key: 'message_type' }, { key: 'content' }]);
    });
  });

  describe('getAutomationType', () => {
    it('returns the correct automation type for the given key', () => {
      const automationTypes = {
        message_created: {
          conditions: [
            { key: 'message_type', inputType: 'select' },
            { key: 'content', inputType: 'text' },
          ],
        },
      };
      const automation = { event_name: 'message_created' };
      const result = automationHelper.getAutomationType(
        automationTypes,
        automation,
        'content'
      );
      expect(result).toEqual({ key: 'content', inputType: 'text' });
    });
  });

  describe('getInputType', () => {
    const allCustomAttributes = [
      { attribute_key: 'test', attribute_display_type: 'text' },
    ];
    const automationTypes = {
      message_created: {
        conditions: [
          { key: 'message_type', inputType: 'select' },
          { key: 'content', inputType: 'text' },
        ],
      },
    };
    const automation = { event_name: 'message_created' };

    it('returns input type for custom attribute', () => {
      const result = automationHelper.getInputType(
        allCustomAttributes,
        automationTypes,
        automation,
        'test'
      );
      expect(result).toBe('plain_text');
    });

    it('returns input type for standard attribute', () => {
      const result = automationHelper.getInputType(
        allCustomAttributes,
        automationTypes,
        automation,
        'message_type'
      );
      expect(result).toBe('select');
    });
  });

  describe('getOperators', () => {
    const allCustomAttributes = [
      { attribute_key: 'test', attribute_display_type: 'text' },
    ];
    const automationTypes = {
      message_created: {
        conditions: [
          { key: 'message_type', filterOperators: OPERATOR_TYPES_1 },
          { key: 'content', filterOperators: OPERATOR_TYPES_3 },
        ],
      },
    };
    const automation = { event_name: 'message_created' };

    it('returns operators for custom attribute in edit mode', () => {
      const result = automationHelper.getOperators(
        allCustomAttributes,
        automationTypes,
        automation,
        'edit',
        'test'
      );
      expect(result).toBe(OPERATOR_TYPES_3);
    });

    it('returns operators for standard attribute', () => {
      const result = automationHelper.getOperators(
        allCustomAttributes,
        automationTypes,
        automation,
        'create',
        'message_type'
      );
      expect(result).toBe(OPERATOR_TYPES_1);
    });
  });

  describe('getCustomAttributeType', () => {
    it('returns custom attribute type for the given key', () => {
      const automationTypes = {
        message_created: {
          conditions: [
            { key: 'message_type', customAttributeType: 'contact_attribute' },
            { key: 'test', customAttributeType: 'conversation_attribute' },
          ],
        },
      };
      const automation = { event_name: 'message_created' };
      const result = automationHelper.getCustomAttributeType(
        automationTypes,
        automation,
        'test'
      );
      expect(result).toBe('conversation_attribute');
    });
  });

  describe('showActionInput', () => {
    const automationActionTypes = [
      { key: 'assign_agent', inputType: 'select' },
      { key: 'send_email_to_team', inputType: null },
    ];

    it('returns false for send_email_to_team', () => {
      expect(
        automationHelper.showActionInput(
          automationActionTypes,
          'send_email_to_team'
        )
      ).toBe(false);
    });

    it('returns true for actions with inputType', () => {
      expect(
        automationHelper.showActionInput(automationActionTypes, 'assign_agent')
      ).toBe(true);
    });
  });
});
