// The events that are about one message rather than about the conversation. Anything keyed on the
// shape of a message -- the default condition the form starts with, the custom attributes offered
// alongside it -- asks this instead of naming one of them, which is how the edit trigger came to be
// offered the conversation's own default condition. #648
export const MESSAGE_LEVEL_EVENTS = ['message_created', 'message_edited'];

// The triggers whose conditions the account's own custom attributes are appended to, which is a
// question about the subject the trigger asks about rather than about the trigger itself: every
// message-level event, plus the conversation events that offer conversation-shaped conditions.
// `conversation_resolved` and `monitor_matched` joined upstream's list in 4.19.0; without them the
// form crashed when switching to those triggers.
//
// Named here, and read by both the pass and its spec, so that adding a trigger is one edit in one
// place and the spec cannot fall behind the list it is asserting over. #667
export const CUSTOM_ATTRIBUTE_EVENTS = [
  ...MESSAGE_LEVEL_EVENTS,
  'conversation_created',
  'conversation_updated',
  'conversation_opened',
  'conversation_resolved',
  'monitor_matched',
];

export const DEFAULT_MESSAGE_CREATED_CONDITION = [
  {
    attribute_key: 'message_type',
    filter_operator: 'equal_to',
    values: {},
    query_operator: 'and',
    custom_attribute_type: '',
  },
];

export const DEFAULT_CONVERSATION_CONDITION = [
  {
    attribute_key: 'browser_language',
    filter_operator: 'equal_to',
    values: {},
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

export const SENDER_TYPE_CONDITION_VALUES = [
  {
    id: 'Contact',
    i18nKey: 'CONTACT',
  },
  {
    id: 'User',
    i18nKey: 'USER',
  },
  {
    id: 'AgentBot',
    i18nKey: 'AGENT_BOT',
  },
  {
    id: 'Captain::Assistant',
    i18nKey: 'CAPTAIN',
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
