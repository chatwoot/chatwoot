export const NOTIFICATION_TYPES = [
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_CREATED',
    value: 'conversation_creation',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_ASSIGNED',
    value: 'conversation_assignment',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_MENTION',
    value: 'conversation_mention',
  },
  {
    label:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.ASSIGNED_CONVERSATION_NEW_MESSAGE',
    value: 'assigned_conversation_new_message',
  },
  {
    label:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.PARTICIPATING_CONVERSATION_NEW_MESSAGE',
    value: 'participating_conversation_new_message',
  },
  {
    label:
      'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_FIRST_RESPONSE',
    value: 'sla_missed_first_response',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_NEXT_RESPONSE',
    value: 'sla_missed_next_response',
  },
  {
    label: 'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.SLA_MISSED_RESOLUTION',
    value: 'sla_missed_resolution',
  },
];

export const EVENT_TYPES = {
  ASSIGNED: 'assigned',
  NOTME: 'notme',
  UNASSIGNED: 'unassigned',
};

export const ALERT_EVENTS = [
  {
    value: EVENT_TYPES.ASSIGNED,
    label: 'assigned',
  },
  {
    value: EVENT_TYPES.UNASSIGNED,
    label: 'unassigned',
  },
  {
    value: EVENT_TYPES.NOTME,
    label: 'notme',
  },
];
