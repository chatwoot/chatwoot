import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from 'dashboard/routes/dashboard/settings/automation/operators';
import filterQueryGenerator from './filterQueryGenerator';
import actionQueryGenerator from './actionQueryGenerator';
const MESSAGE_CONDITION_VALUES = [
  {
    id: 'incoming',
    name: 'Incoming Message',
  },
  {
    id: 'outgoing',
    name: 'Outgoing Message',
  },
];

export const getCustomAttributeInputType = key => {
  const customAttributeMap = {
    date: 'date',
    text: 'plain_text',
    list: 'search_select',
    checkbox: 'search_select',
  };

  return customAttributeMap[key] || 'plain_text';
};

export const isACustomAttribute = (customAttributes, key) => {
  return customAttributes.find(attr => {
    return attr.attribute_key === key;
  });
};

export const getCustomAttributeListDropdownValues = (
  customAttributes,
  type
) => {
  return customAttributes
    .find(attr => attr.attribute_key === type)
    .attribute_values.map(item => {
      return {
        id: item,
        name: item,
      };
    });
};

export const isCustomAttributeCheckbox = (customAttributes, key) => {
  return customAttributes.find(attr => {
    return (
      attr.attribute_key === key && attr.attribute_display_type === 'checkbox'
    );
  });
};

export const isCustomAttributeList = (customAttributes, type) => {
  return customAttributes.find(attr => {
    return (
      attr.attribute_key === type && attr.attribute_display_type === 'list'
    );
  });
};

export const getOperatorTypes = key => {
  const operatorMap = {
    list: OPERATOR_TYPES_1,
    text: OPERATOR_TYPES_3,
    number: OPERATOR_TYPES_1,
    link: OPERATOR_TYPES_1,
    date: OPERATOR_TYPES_4,
    checkbox: OPERATOR_TYPES_1,
  };

  return operatorMap[key] || OPERATOR_TYPES_1;
};

export const generateCustomAttributeTypes = (customAttributes, type) => {
  return customAttributes.map(attr => {
    return {
      key: attr.attribute_key,
      name: attr.attribute_display_name,
      inputType: getCustomAttributeInputType(attr.attribute_display_type),
      filterOperators: getOperatorTypes(attr.attribute_display_type),
      customAttributeType: type,
    };
  });
};

export const generateConditionOptions = (options, key = 'id') => {
  return options.map(i => {
    return {
      id: i[key],
      name: i.title,
    };
  });
};

export const getActionOptions = ({ agents, teams, labels, type }) => {
  const actionsMap = {
    assign_agent: agents,
    assign_team: teams,
    send_email_to_team: teams,
    add_label: generateConditionOptions(labels, 'title'),
  };
  return actionsMap[type];
};

export const getConditionOptions = ({
  agents,
  booleanFilterOptions,
  campaigns,
  contacts,
  countries,
  customAttributes,
  inboxes,
  languages,
  statusFilterOptions,
  teams,
  type,
}) => {
  if (isCustomAttributeCheckbox(customAttributes, type)) {
    return booleanFilterOptions;
  }

  if (isCustomAttributeList(customAttributes, type)) {
    return getCustomAttributeListDropdownValues(customAttributes, type);
  }

  const conditionFilterMaps = {
    status: statusFilterOptions,
    assignee_id: agents,
    contact: contacts,
    inbox_id: inboxes,
    team_id: teams,
    campaigns: generateConditionOptions(campaigns),
    browser_language: languages,
    country_code: countries,
    message_type: MESSAGE_CONDITION_VALUES,
  };

  return conditionFilterMaps[type];
};

export const getFileName = (action, files = []) => {
  const blobId = action.action_params[0];
  if (!blobId) return '';
  if (action.action_name === 'send_attachment') {
    const file = files.find(item => item.blob_id === blobId);
    if (file) return file.filename.toString();
  }
  return '';
};

export const getDefaultConditions = eventName => {
  if (eventName === 'message_created') {
    return [
      {
        attribute_key: 'message_type',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ];
  }
  if (eventName === 'conversation_opened') {
    return [
      {
        attribute_key: 'browser_language',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ];
  }
  return [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    },
  ];
};

export const getDefaultActions = () => {
  return [
    {
      action_name: 'assign_agent',
      action_params: [],
    },
  ];
};

export const filterCustomAttributes = customAttributes => {
  return customAttributes.map(attr => {
    return {
      key: attr.attribute_key,
      name: attr.attribute_display_name,
      type: attr.attribute_display_type,
    };
  });
};

export const getStandardAttributeInputType = (automationTypes, event, key) => {
  return automationTypes[event].conditions.find(item => item.key === key)
    .inputType;
};

export const generateAutomationPayload = payload => {
  const automation = JSON.parse(JSON.stringify(payload));
  automation.conditions[automation.conditions.length - 1].query_operator = null;
  automation.conditions = filterQueryGenerator(automation.conditions).payload;
  automation.actions = actionQueryGenerator(automation.actions);
  return automation;
};

export const isCustomAttribute = (attrs, key) => {
  return attrs.find(attr => attr.key === key);
};

export const generateCustomAttributes = (
  conversationAttributes = [],
  contactAttributes = [],
  conversationlabel,
  contactlabel
) => {
  const customAttributes = [];
  if (conversationAttributes.length) {
    customAttributes.push(
      {
        key: `conversation_custom_attribute`,
        name: conversationlabel,
        disabled: true,
      },
      ...conversationAttributes
    );
  }
  if (contactAttributes.length) {
    customAttributes.push(
      {
        key: `contact_custom_attribute`,
        name: contactlabel,
        disabled: true,
      },
      ...contactAttributes
    );
  }
  return customAttributes;
};
