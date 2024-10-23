import * as helpers from 'dashboard/helper/automationHelper';
import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from 'dashboard/routes/dashboard/settings/automation/operators';
import {
  customAttributes,
  labels,
  automation,
  contactAttrs,
  conversationAttrs,
  expectedOutputForCustomAttributeGenerator,
} from './fixtures/automationFixtures';
import { AUTOMATIONS } from 'dashboard/routes/dashboard/settings/automation/constants';

describe('getCustomAttributeInputType', () => {
  it('returns the attribute input type', () => {
    expect(helpers.getCustomAttributeInputType('date')).toEqual('date');
    expect(helpers.getCustomAttributeInputType('date')).not.toEqual(
      'some_random_value'
    );
    expect(helpers.getCustomAttributeInputType('text')).toEqual('plain_text');
    expect(helpers.getCustomAttributeInputType('list')).toEqual(
      'search_select'
    );
    expect(helpers.getCustomAttributeInputType('checkbox')).toEqual(
      'search_select'
    );
    expect(helpers.getCustomAttributeInputType('some_random_text')).toEqual(
      'plain_text'
    );
  });
});

describe('isACustomAttribute', () => {
  it('returns the custom attribute value if true', () => {
    expect(
      helpers.isACustomAttribute(customAttributes, 'signed_up_at')
    ).toBeTruthy();
    expect(helpers.isACustomAttribute(customAttributes, 'status')).toBeFalsy();
  });
});

describe('getCustomAttributeListDropdownValues', () => {
  it('returns the attribute dropdown values', () => {
    const myListValues = [
      { id: 'item1', name: 'item1' },
      { id: 'item2', name: 'item2' },
      { id: 'item3', name: 'item3' },
    ];
    expect(
      helpers.getCustomAttributeListDropdownValues(customAttributes, 'my_list')
    ).toEqual(myListValues);
  });
});

describe('isCustomAttributeCheckbox', () => {
  it('checks if attribute is a checkbox', () => {
    expect(
      helpers.isCustomAttributeCheckbox(customAttributes, 'prime_user')
        .attribute_display_type
    ).toEqual('checkbox');
    expect(
      helpers.isCustomAttributeCheckbox(customAttributes, 'my_check')
        .attribute_display_type
    ).toEqual('checkbox');
    expect(
      helpers.isCustomAttributeCheckbox(customAttributes, 'my_list')
    ).not.toEqual('checkbox');
  });
});

describe('isCustomAttributeList', () => {
  it('checks if attribute is a list', () => {
    expect(
      helpers.isCustomAttributeList(customAttributes, 'my_list')
        .attribute_display_type
    ).toEqual('list');
  });
});

describe('getOperatorTypes', () => {
  it('returns the correct custom attribute operators', () => {
    expect(helpers.getOperatorTypes('list')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('text')).toEqual(OPERATOR_TYPES_3);
    expect(helpers.getOperatorTypes('number')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('link')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('date')).toEqual(OPERATOR_TYPES_4);
    expect(helpers.getOperatorTypes('checkbox')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('some_random')).toEqual(OPERATOR_TYPES_1);
  });
});

describe('generateConditionOptions', () => {
  it('returns expected conditions options array', () => {
    const testConditions = [
      { id: 123, title: 'Fayaz', email: 'test@test.com' },
      { title: 'John', id: 324, email: 'test@john.com' },
    ];
    const expectedConditions = [
      { id: 123, name: 'Fayaz' },
      { id: 324, name: 'John' },
    ];
    expect(helpers.generateConditionOptions(testConditions)).toEqual(
      expectedConditions
    );
  });
});

describe('getActionOptions', () => {
  it('returns expected actions options array', () => {
    const expectedOptions = [
      { id: 'testlabel', name: 'testlabel' },
      { id: 'snoozes', name: 'snoozes' },
    ];
    expect(helpers.getActionOptions({ labels, type: 'add_label' })).toEqual(
      expectedOptions
    );
  });
});

describe('getConditionOptions', () => {
  it('returns expected conditions options', () => {
    const testOptions = [
      { id: 'open', name: 'Open' },
      { id: 'resolved', name: 'Resolved' },
      { id: 'pending', name: 'Pending' },
      { id: 'snoozed', name: 'Snoozed' },
      { id: 'all', name: 'All' },
    ];
    expect(
      helpers.getConditionOptions({
        customAttributes,
        campaigns: [],
        statusFilterOptions: testOptions,
        type: 'status',
      })
    ).toEqual(testOptions);
  });
});

describe('getFileName', () => {
  it('returns the correct file name', () => {
    expect(
      helpers.getFileName(automation.actions[0], automation.files)
    ).toEqual('pfp.jpeg');
  });
});

describe('getDefaultConditions', () => {
  it('returns the resp default condition model', () => {
    const messageCreatedModel = [
      {
        attribute_key: 'message_type',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ];
    const genericConditionModel = [
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ];
    expect(helpers.getDefaultConditions('message_created')).toEqual(
      messageCreatedModel
    );
    expect(helpers.getDefaultConditions()).toEqual(genericConditionModel);
  });
});

describe('getDefaultActions', () => {
  it('returns the resp default action model', () => {
    const genericActionModel = [
      {
        action_name: 'assign_agent',
        action_params: [],
      },
    ];
    expect(helpers.getDefaultActions()).toEqual(genericActionModel);
  });
});

describe('filterCustomAttributes', () => {
  it('filters the raw custom attributes', () => {
    const filteredAttributes = [
      { key: 'signed_up_at', name: 'Signed Up At', type: 'date' },
      { key: 'prime_user', name: 'Prime User', type: 'checkbox' },
      { key: 'test', name: 'Test', type: 'text' },
      { key: 'link', name: 'Link', type: 'link' },
      { key: 'my_list', name: 'My List', type: 'list' },
      { key: 'my_check', name: 'My Check', type: 'checkbox' },
      { key: 'conlist', name: 'ConList', type: 'list' },
      { key: 'asdf', name: 'asdf', type: 'link' },
    ];
    expect(helpers.filterCustomAttributes(customAttributes)).toEqual(
      filteredAttributes
    );
  });
});

describe('getStandardAttributeInputType', () => {
  it('returns the resp default action model', () => {
    expect(
      helpers.getStandardAttributeInputType(
        AUTOMATIONS,
        'message_created',
        'message_type'
      )
    ).toEqual('search_select');
    expect(
      helpers.getStandardAttributeInputType(
        AUTOMATIONS,
        'conversation_created',
        'status'
      )
    ).toEqual('multi_select');
    expect(
      helpers.getStandardAttributeInputType(
        AUTOMATIONS,
        'conversation_updated',
        'referer'
      )
    ).toEqual('plain_text');
  });
});

describe('generateAutomationPayload', () => {
  it('returns the resp default action model', () => {
    const testPayload = {
      name: 'Test',
      description: 'This is a test',
      event_name: 'conversation_created',
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'and',
        },
      ],
      actions: [
        {
          action_name: 'add_label',
          action_params: [{ id: 2, name: 'testlabel' }],
        },
      ],
    };
    const expectedPayload = {
      name: 'Test',
      description: 'This is a test',
      event_name: 'conversation_created',
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: ['open'],
        },
      ],
      actions: [
        {
          action_name: 'add_label',
          action_params: [2],
        },
      ],
    };
    expect(helpers.generateAutomationPayload(testPayload)).toEqual(
      expectedPayload
    );
  });
});

describe('isCustomAttribute', () => {
  it('returns the resp default action model', () => {
    const attrs = helpers.filterCustomAttributes(customAttributes);
    expect(helpers.isCustomAttribute(attrs, 'my_list')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'my_check')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'signed_up_at')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'link')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'prime_user')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'hello')).toBeFalsy();
  });
});

describe('generateCustomAttributes', () => {
  it('generates and returns correct condition attribute', () => {
    expect(
      helpers.generateCustomAttributes(
        conversationAttrs,
        contactAttrs,
        'Conversation Custom Attributes',
        'Contact Custom Attributes'
      )
    ).toEqual(expectedOutputForCustomAttributeGenerator);
  });
});

describe('getAttributes', () => {
  it('returns the conditions for the given automation type', () => {
    const result = helpers.getAttributes(AUTOMATIONS, 'message_created');
    expect(result).toEqual(AUTOMATIONS.message_created.conditions);
  });
});

describe('getAttributes', () => {
  it('returns the conditions for the given automation type', () => {
    const result = helpers.getAttributes(AUTOMATIONS, 'message_created');
    expect(result).toEqual(AUTOMATIONS.message_created.conditions);
  });
});

describe('getAutomationType', () => {
  it('returns the automation type for the given key', () => {
    const mockAutomation = { event_name: 'message_created' };
    const result = helpers.getAutomationType(
      AUTOMATIONS,
      mockAutomation,
      'message_type'
    );
    expect(result).toEqual(
      AUTOMATIONS.message_created.conditions.find(c => c.key === 'message_type')
    );
  });
});

describe('getInputType', () => {
  it('returns the input type for a custom attribute', () => {
    const mockAutomation = { event_name: 'message_created' };
    const result = helpers.getInputType(
      customAttributes,
      AUTOMATIONS,
      mockAutomation,
      'signed_up_at'
    );
    expect(result).toEqual('date');
  });

  it('returns the input type for a standard attribute', () => {
    const mockAutomation = { event_name: 'message_created' };
    const result = helpers.getInputType(
      customAttributes,
      AUTOMATIONS,
      mockAutomation,
      'message_type'
    );
    expect(result).toEqual('search_select');
  });
});

describe('getOperators', () => {
  it('returns operators for a custom attribute in edit mode', () => {
    const mockAutomation = { event_name: 'message_created' };
    const result = helpers.getOperators(
      customAttributes,
      AUTOMATIONS,
      mockAutomation,
      'edit',
      'signed_up_at'
    );
    expect(result).toEqual(OPERATOR_TYPES_4);
  });

  it('returns operators for a standard attribute', () => {
    const mockAutomation = { event_name: 'message_created' };
    const result = helpers.getOperators(
      customAttributes,
      AUTOMATIONS,
      mockAutomation,
      'create',
      'message_type'
    );
    expect(result).toEqual(
      AUTOMATIONS.message_created.conditions.find(c => c.key === 'message_type')
        .filterOperators
    );
  });
});

describe('getCustomAttributeType', () => {
  it('returns the custom attribute type for the given key', () => {
    const mockAutomation = { event_name: 'message_created' };
    const result = helpers.getCustomAttributeType(
      AUTOMATIONS,
      mockAutomation,
      'message_type'
    );
    expect(result).toEqual(
      AUTOMATIONS.message_created.conditions.find(c => c.key === 'message_type')
        .customAttributeType
    );
  });
});

describe('showActionInput', () => {
  it('returns false for send_email_to_team and send_message actions', () => {
    expect(helpers.showActionInput([], 'send_email_to_team')).toBe(false);
    expect(helpers.showActionInput([], 'send_message')).toBe(false);
  });

  it('returns true if the action has an input type', () => {
    const mockActionTypes = [{ key: 'add_label', inputType: 'select' }];
    expect(helpers.showActionInput(mockActionTypes, 'add_label')).toBe(true);
  });

  it('returns false if the action does not have an input type', () => {
    const mockActionTypes = [{ key: 'some_action', inputType: null }];
    expect(helpers.showActionInput(mockActionTypes, 'some_action')).toBe(false);
  });
});
