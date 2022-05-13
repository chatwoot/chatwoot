import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from '../routes/dashboard/settings/automation/operators';

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

export const generateCustomAttributeTypes = customAttributes => {
  return customAttributes.map(attr => {
    return {
      key: attr.attribute_key,
      name: attr.attribute_display_name,
      inputType: getCustomAttributeInputType(attr.attribute_display_type),
      filterOperators: getOperatorTypes(attr.attribute_display_type),
    };
  });
};

const generateConditionOptions = options =>
  options.map(i => {
    return {
      id: i.id,
      name: i.title,
    };
  });

export const getActionOptions = ({ teams, labels, type }) => {
  const actionsMap = {
    assign_team: teams,
    send_email_to_team: teams,
    add_label: generateConditionOptions(labels),
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
  labels,
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
    labels: generateConditionOptions(labels),
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
