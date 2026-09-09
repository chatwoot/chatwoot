export const AVAILABLE_CUSTOM_ROLE_PERMISSIONS = [
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
  'contact_manage',
  'contact_inbox_manage',
  'contact_edit',
  'contact_delete',
  'report_manage',
  'report_overview',
  'report_conversation',
  'report_agent',
  'report_agent_activity',
  'report_inbox',
  'report_team',
  'report_label',
  'report_csat',
  'report_sla',
  'report_bot',
  'report_queued_customers',
  'knowledge_base_manage',
];

export const ROLES = ['agent', 'administrator'];

export const CONVERSATION_PERMISSIONS = [
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
];

export const MANAGE_ALL_CONVERSATION_PERMISSIONS = 'conversation_manage';

export const CONVERSATION_UNASSIGNED_PERMISSIONS =
  'conversation_unassigned_manage';

export const CONVERSATION_PARTICIPATING_PERMISSIONS =
  'conversation_participating_manage';

export const CONTACT_PERMISSIONS = 'contact_manage';

export const CONTACT_INBOX_PERMISSIONS = 'contact_inbox_manage';

export const CONTACT_ACCESS_PERMISSIONS = [
  CONTACT_PERMISSIONS,
  CONTACT_INBOX_PERMISSIONS,
];

export const REPORTS_PERMISSIONS = 'report_manage';

export const REPORT_PAGE_PERMISSIONS = [
  'report_overview',
  'report_conversation',
  'report_agent',
  'report_agent_activity',
  'report_inbox',
  'report_team',
  'report_label',
  'report_csat',
  'report_sla',
  'report_bot',
  'report_queued_customers',
];

export const PORTAL_PERMISSIONS = 'knowledge_base_manage';

export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  me: {
    count: 'mineCount',
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  },
  unassigned: {
    count: 'unAssignedCount',
    permissions: [
      ...ROLES,
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_UNASSIGNED_PERMISSIONS,
    ],
  },
  all: {
    count: 'allCount',
    permissions: [
      ...ROLES,
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_PARTICIPATING_PERMISSIONS,
    ],
  },
};
