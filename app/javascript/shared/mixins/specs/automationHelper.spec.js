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
} from './automationFixtures';
import { AUTOMATIONS } from 'dashboard/routes/dashboard/settings/automation/constants';

describe('automationMethodsMixin', () => {
  it('getCustomAttributeInputType returns the attribute input type', () => {
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
  it('isACustomAttribute returns the custom attribute value if true', () => {
    expect(
      helpers.isACustomAttribute(customAttributes, 'signed_up_at')
    ).toBeTruthy();
    expect(helpers.isACustomAttribute(customAttributes, 'status')).toBeFalsy();
  });
  it('getCustomAttributeListDropdownValues returns the attribute dropdown values', () => {
    const myListValues = [
      {
        id: 'item1',
        name: 'item1',
      },
      {
        id: 'item2',
        name: 'item2',
      },
      {
        id: 'item3',
        name: 'item3',
      },
    ];
    expect(
      helpers.getCustomAttributeListDropdownValues(customAttributes, 'my_list')
    ).toEqual(myListValues);
  });

  it('isCustomAttributeCheckbox checks if attribute is a checkbox', () => {
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
  it('isCustomAttributeList checks if attribute is a list', () => {
    expect(
      helpers.isCustomAttributeList(customAttributes, 'my_list')
        .attribute_display_type
    ).toEqual('list');
  });
  it('getOperatorTypes returns the correct custom attribute operators', () => {
    expect(helpers.getOperatorTypes('list')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('text')).toEqual(OPERATOR_TYPES_3);
    expect(helpers.getOperatorTypes('number')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('link')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('date')).toEqual(OPERATOR_TYPES_4);
    expect(helpers.getOperatorTypes('checkbox')).toEqual(OPERATOR_TYPES_1);
    expect(helpers.getOperatorTypes('some_random')).toEqual(OPERATOR_TYPES_1);
  });
  it('generateConditionOptions returns expected conditions options array', () => {
    const testConditions = [
      {
        id: 123,
        title: 'Fayaz',
        email: 'test@test.com',
      },
      {
        title: 'John',
        id: 324,
        email: 'test@john.com',
      },
    ];

    const expectedConditions = [
      {
        id: 123,
        name: 'Fayaz',
      },
      {
        id: 324,
        name: 'John',
      },
    ];
    expect(helpers.generateConditionOptions(testConditions)).toEqual(
      expectedConditions
    );
  });
  it('getActionOptions returns expected actions options array', () => {
    const expectedOptions = [
      {
        id: 'testlabel',
        name: 'testlabel',
      },
      {
        id: 'snoozes',
        name: 'snoozes',
      },
    ];
    expect(helpers.getActionOptions({ labels, type: 'add_label' })).toEqual(
      expectedOptions
    );
  });
  it('getConditionOptions returns expected conditions options', () => {
    const testOptions = [
      {
        id: 'open',
        name: 'Open',
      },
      {
        id: 'resolved',
        name: 'Resolved',
      },
      {
        id: 'pending',
        name: 'Pending',
      },
      {
        id: 'snoozed',
        name: 'Snoozed',
      },
      {
        id: 'all',
        name: 'All',
      },
    ];
    const expectedOptions = [
      {
        id: 'open',
        name: 'Open',
      },
      {
        id: 'resolved',
        name: 'Resolved',
      },
      {
        id: 'pending',
        name: 'Pending',
      },
      {
        id: 'snoozed',
        name: 'Snoozed',
      },
      {
        id: 'all',
        name: 'All',
      },
    ];
    expect(
      helpers.getConditionOptions({
        customAttributes,
        campaigns: [],
        statusFilterOptions: testOptions,
        type: 'status',
      })
    ).toEqual(expectedOptions);
  });
  it('getFileName returns the correct file name', () => {
    expect(
      helpers.getFileName(automation.actions[0], automation.files)
    ).toEqual('pfp.jpeg');
  });
  it('getDefaultConditions returns the resp default condition model', () => {
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
  it('getDefaultActions returns the resp default action model', () => {
    const genericActionModel = [
      {
        action_name: 'assign_team',
        action_params: [],
      },
    ];
    expect(helpers.getDefaultActions()).toEqual(genericActionModel);
  });
  it('filterCustomAttributes filters the raw custom attributes', () => {
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
  it('getStandardAttributeInputType returns the resp default action model', () => {
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
  it('generateAutomationPayload returns the resp default action model', () => {
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
  it('isCustomAttribute returns the resp default action model', () => {
    const attrs = helpers.filterCustomAttributes(customAttributes);
    expect(helpers.isCustomAttribute(attrs, 'my_list')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'my_check')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'signed_up_at')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'link')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'prime_user')).toBeTruthy();
    expect(helpers.isCustomAttribute(attrs, 'hello')).toBeFalsy();
  });

  it('generateCustomAttributes generates and returns correct condition attribute', () => {
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
