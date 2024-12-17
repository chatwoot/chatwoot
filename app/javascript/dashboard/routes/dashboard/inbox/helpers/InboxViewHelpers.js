export const NOTIFICATION_TYPES_MAPPING = {
  CONVERSATION_MENTION: ['i-lucide-at-sign', 'text-n-blue-text'],
  CONVERSATION_ASSIGNMENT: ['i-lucide-chevrons-right', 'text-n-blue-text'],
  CONVERSATION_CREATION: ['i-lucide-mail-plus', 'text-n-blue-text'],
  PARTICIPATING_CONVERSATION_NEW_MESSAGE: [
    'i-lucide-message-square-plus',
    'text-n-blue-text',
  ],
  ASSIGNED_CONVERSATION_NEW_MESSAGE: [
    'i-lucide-message-square-plus',
    'text-n-blue-text',
  ],
  SLA_MISSED_FIRST_RESPONSE: ['i-lucide-heart-crack', 'text-n-ruby-11'],
  SLA_MISSED_NEXT_RESPONSE: ['i-lucide-heart-crack', 'text-n-ruby-11'],
  SLA_MISSED_RESOLUTION: ['i-lucide-heart-crack', 'text-n-ruby-11'],
};

export const NOTIFICATION_TYPES_WITHOUT_MESSAGE = [
  'conversation_creation',
  'conversation_assignment',
  'sla_missed_first_response',
  'sla_missed_next_response',
  'sla_missed_resolution',
];
