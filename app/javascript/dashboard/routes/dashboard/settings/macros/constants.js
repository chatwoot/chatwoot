export const MACRO_ACTION_TYPES = [
  {
    key: 'assign_team',
    label: 'Assign a team',
    inputType: 'search_select',
  },
  {
    key: 'assign_agent',
    label: 'Assign an agent',
    inputType: 'search_select',
  },
  {
    key: 'add_label',
    label: 'Add a label',
    inputType: 'multi_select',
  },
  {
    key: 'remove_label',
    label: 'Remove a label',
    inputType: 'multi_select',
  },
  {
    key: 'remove_assigned_team',
    label: 'Remove Assigned Team',
    inputType: null,
  },
  {
    key: 'send_email_transcript',
    label: 'Send an email transcript',
    inputType: 'email',
  },
  {
    key: 'mute_conversation',
    label: 'Mute conversation',
    inputType: null,
  },
  {
    key: 'snooze_conversation',
    label: 'Snooze conversation',
    inputType: null,
  },
  {
    key: 'resolve_conversation',
    label: 'Resolve conversation',
    inputType: null,
  },
  {
    key: 'send_attachment',
    label: 'Send Attachment',
    inputType: 'attachment',
  },
  {
    key: 'send_message',
    label: 'Send a message',
    inputType: 'textarea',
  },
  {
    key: 'add_private_note',
    label: 'Add a private note',
    inputType: 'textarea',
  },
  {
    key: 'change_priority',
    label: 'Change Priority',
    inputType: 'search_select',
  },
];
