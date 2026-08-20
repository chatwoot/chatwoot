import {
  DEFAULT_ACTIONS,
  DEFAULT_CONVERSATION_CONDITION,
  DEFAULT_MESSAGE_CREATED_CONDITION,
  DEFAULT_OTHER_CONDITION,
} from 'dashboard/constants/automation';
import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from 'dashboard/routes/dashboard/settings/automation/operators';
import actionQueryGenerator from './actionQueryGenerator';
import filterQueryGenerator from './filterQueryGenerator';

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
      attributeDisplayType: attr.attribute_display_type,
      filterOperators: getOperatorTypes(attr.attribute_display_type),
      customAttributeType: type,
    };
  });
};

// Leading icon per action key, shared by the automation and macro action pickers.
const ACTION_ICONS = {
  assign_agent: 'i-lucide-user-round',
  assign_team: 'i-lucide-users-round',
  remove_assigned_agent: 'i-lucide-user-round-x',
  remove_assigned_team: 'i-lucide-users',
  add_label: 'i-lucide-tag',
  remove_label: 'i-woot-tag-remove',
  send_email_to_team: 'i-lucide-send',
  send_email_transcript: 'i-lucide-mail',
  send_message: 'i-lucide-message-square',
  add_private_note: 'i-lucide-sticky-note',
  send_attachment: 'i-lucide-paperclip',
  send_webhook_event: 'i-lucide-webhook',
  mute_conversation: 'i-lucide-bell-off',
  snooze_conversation: 'i-lucide-clock',
  open_conversation: 'i-lucide-circle-dot',
  pending_conversation: 'i-lucide-circle-dashed',
  resolve_conversation: 'i-lucide-circle-check',
  change_priority: 'i-lucide-signal-high',
  add_sla: 'i-lucide-gauge',
};

const DEFAULT_ACTION_ICON = 'i-lucide-zap';

/**
 * Resolve the leading icon for an automation or macro action.
 * @param {string} key - The action key.
 * @returns {string} Icon class.
 */
export const getActionIcon = key => ACTION_ICONS[key] || DEFAULT_ACTION_ICON;

export const generateConditionOptions = (options, key = 'id') => {
  if (!options || !Array.isArray(options)) return [];
  return options.map(i => {
    return {
      id: i[key],
      name: i.title,
    };
  });
};

// Teams carry an emoji icon picker value in `icon`, which is not a CSS class and
// cannot be handed to the generic Icon component the dropdowns render.
export const generateTeamOptions = teams =>
  (teams || []).map(team => ({
    id: team.id,
    name: team.name,
    emoji: team.icon,
    iconColor: team.icon_color,
  }));

export const generateLabelOptions = labels =>
  (labels || []).map(label => ({
    id: label.title,
    name: label.title,
    color: label.color,
  }));

export const getActionOptions = ({
  agents,
  teams,
  labels,
  slaPolicies,
  type,
  addNoneToListFn,
  priorityOptions,
}) => {
  const actionsMap = {
    assign_agent: addNoneToListFn ? addNoneToListFn(agents) : agents,
    assign_team: addNoneToListFn
      ? addNoneToListFn(generateTeamOptions(teams))
      : generateTeamOptions(teams),
    send_email_to_team: generateTeamOptions(teams),
    add_label: generateLabelOptions(labels),
    remove_label: generateLabelOptions(labels),
    change_priority: priorityOptions,
    add_sla: slaPolicies,
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
  labels,
  statusFilterOptions,
  teams,
  type,
  priorityOptions,
  messageTypeOptions,
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
    team_id: generateTeamOptions(teams),
    campaigns: generateConditionOptions(campaigns),
    browser_language: languages,
    conversation_language: languages,
    country_code: countries,
    message_type: messageTypeOptions,
    private_note: booleanFilterOptions,
    priority: priorityOptions,
    labels: generateLabelOptions(labels),
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
    return structuredClone(DEFAULT_MESSAGE_CREATED_CONDITION);
  }
  if (
    eventName === 'conversation_opened' ||
    eventName === 'conversation_resolved'
  ) {
    return structuredClone(DEFAULT_CONVERSATION_CONDITION);
  }
  return structuredClone(DEFAULT_OTHER_CONDITION);
};

export const getDefaultActions = () => {
  return structuredClone(DEFAULT_ACTIONS);
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

export const formatDelay = minutes => {
  if (minutes % 1440 === 0) return `${minutes / 1440}d`;
  if (minutes % 60 === 0) return `${minutes / 60}h`;
  return `${minutes}m`;
};

export const isCustomAttribute = (attrs, key) => {
  return attrs.find(attr => attr.key === key);
};

export const generateCustomAttributes = (
  // eslint-disable-next-line default-param-last
  conversationAttributes = [],
  // eslint-disable-next-line default-param-last
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

/**
 * Get attributes for a given key from automation types.
 * @param {Object} automationTypes - Object containing automation types.
 * @param {string} key - The key to get attributes for.
 * @returns {Array} Array of condition objects for the given key.
 */
export const getAttributes = (automationTypes, key) => {
  return automationTypes[key].conditions;
};

/**
 * Get the automation type for a given key.
 * @param {Object} automationTypes - Object containing automation types.
 * @param {Object} automation - The automation object.
 * @param {string} key - The key to get the automation type for.
 * @returns {Object} The automation type object.
 */
export const getAutomationType = (automationTypes, automation, key) => {
  return automationTypes[automation.event_name].conditions.find(
    condition => condition.key === key
  );
};

/**
 * Get the input type for a given key.
 * @param {Array} allCustomAttributes - Array of all custom attributes.
 * @param {Object} automationTypes - Object containing automation types.
 * @param {Object} automation - The automation object.
 * @param {string} key - The key to get the input type for.
 * @returns {string} The input type.
 */
export const getInputType = (
  allCustomAttributes,
  automationTypes,
  automation,
  key
) => {
  const customAttribute = isACustomAttribute(allCustomAttributes, key);
  if (customAttribute) {
    return getCustomAttributeInputType(customAttribute.attribute_display_type);
  }
  const type = getAutomationType(automationTypes, automation, key);
  return type.inputType;
};

/**
 * Get operators for a given key.
 * @param {Array} allCustomAttributes - Array of all custom attributes.
 * @param {Object} automationTypes - Object containing automation types.
 * @param {Object} automation - The automation object.
 * @param {string} mode - The mode ('edit' or other).
 * @param {string} key - The key to get operators for.
 * @returns {Array} Array of operators.
 */
export const getOperators = (
  allCustomAttributes,
  automationTypes,
  automation,
  mode,
  key
) => {
  if (mode === 'edit') {
    const customAttribute = isACustomAttribute(allCustomAttributes, key);
    if (customAttribute) {
      return getOperatorTypes(customAttribute.attribute_display_type);
    }
  }
  const type = getAutomationType(automationTypes, automation, key);
  return type.filterOperators;
};

/**
 * Get the custom attribute type for a given key.
 * @param {Object} automationTypes - Object containing automation types.
 * @param {Object} automation - The automation object.
 * @param {string} key - The key to get the custom attribute type for.
 * @returns {string} The custom attribute type.
 */
export const getCustomAttributeType = (automationTypes, automation, key) => {
  return automationTypes[automation.event_name].conditions.find(
    i => i.key === key
  ).customAttributeType;
};

/**
 * Determine if an action input should be shown.
 * @param {Array} automationActionTypes - Array of automation action type objects.
 * @param {string} action - The action to check.
 * @returns {boolean} True if the action input should be shown, false otherwise.
 */
export const showActionInput = (automationActionTypes, action) => {
  if (action === 'send_email_to_team' || action === 'send_message')
    return false;
  const type = automationActionTypes.find(i => i.key === action).inputType;
  return !!type;
};
