export const DEFAULT_MESSAGE_CREATED_CONDITION = [
  {
    attribute_key: 'message_type',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
    custom_attribute_type: '',
  },
];

export const DEFAULT_CONVERSATION_CONDITION = [
  {
    attribute_key: 'browser_language',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
    custom_attribute_type: '',
  },
];

export const DEFAULT_OTHER_CONDITION = [
  {
    attribute_key: 'status',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
    custom_attribute_type: '',
  },
];

export const DEFAULT_ACTIONS = [
  {
    action_name: 'assign_agent',
    action_params: [],
  },
];

export const MESSAGE_CONDITION_VALUES = [
  {
    id: 'incoming',
    name: 'Incoming',
    i18nKey: 'INCOMING',
  },
  {
    id: 'outgoing',
    name: 'Outgoing',
    i18nKey: 'OUTGOING',
  },
];

export const PRIORITY_CONDITION_VALUES = [
  {
    id: 'nil',
    name: 'None',
    i18nKey: 'NONE',
  },
  {
    id: 'low',
    name: 'Low',
    i18nKey: 'LOW',
  },
  {
    id: 'medium',
    name: 'Medium',
    i18nKey: 'MEDIUM',
  },
  {
    id: 'high',
    name: 'High',
    i18nKey: 'HIGH',
  },
  {
    id: 'urgent',
    name: 'Urgent',
    i18nKey: 'URGENT',
  },
];

// Presets accepted by the `mute_conversation` action; must match
// ConversationMuteDurations::PRESETS on the backend.
export const MUTE_DURATION_VALUES = [
  { id: 'permanent', i18nKey: 'PERMANENT' },
  { id: '1_hour', i18nKey: 'ONE_HOUR' },
  { id: '8_hours', i18nKey: 'EIGHT_HOURS' },
  { id: '1_day', i18nKey: 'ONE_DAY' },
  { id: '7_days', i18nKey: 'SEVEN_DAYS' },
];
