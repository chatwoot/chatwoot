export const ROLE_PERMISSIONS = ['agent', 'administrator'];

export const CONVERSATION_PERMISSIONS = [
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
];

export const CONVERSATION_UNASSIGNED_PERMISSIONS = [
  'conversation_manage',
  'conversation_unassigned_manage',
];

export const CONVERSATION_PARTICIPATING_PERMISSIONS = [
  'conversation_manage',
  'conversation_participating_manage',
];

export const CONTACT_PERMISSIONS = ['contact_manage'];

export const REPORTS_PERMISSIONS = ['report_manage'];

export const PORTAL_PERMISSIONS = ['knowledge_base_manage'];

export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  me: {
    count: 'mineCount',
    permissions: [...ROLE_PERMISSIONS, ...CONVERSATION_PERMISSIONS],
  },
  unassigned: {
    count: 'unAssignedCount',
    permissions: [...ROLE_PERMISSIONS, ...CONVERSATION_UNASSIGNED_PERMISSIONS],
  },
  all: {
    count: 'allCount',
    permissions: [
      ...ROLE_PERMISSIONS,
      ...CONVERSATION_PARTICIPATING_PERMISSIONS,
    ],
  },
};
