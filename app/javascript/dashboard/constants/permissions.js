// CommMate: Available permissions that can be assigned per-user
export const AVAILABLE_PERMISSIONS = [
  // Conversation permissions
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
  // Feature access permissions
  'contact_manage',
  'report_manage',
  'knowledge_base_manage',
  'campaign_manage',
  'templates_manage',
  'settings_macros_manage',
  // Settings section permissions
  'settings_account_manage',
  'settings_agents_manage',
  'settings_teams_manage',
  'settings_inboxes_manage',
  'settings_labels_manage',
  'settings_custom_attributes_manage',
  'settings_automation_manage',
  'settings_agent_bots_manage',
  'settings_integrations_manage',
];

// Legacy alias for backwards compatibility
export const AVAILABLE_CUSTOM_ROLE_PERMISSIONS = AVAILABLE_PERMISSIONS;

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

export const REPORTS_PERMISSIONS = 'report_manage';

export const PORTAL_PERMISSIONS = 'knowledge_base_manage';

// CommMate: WhatsApp templates permission
export const TEMPLATES_PERMISSIONS = 'templates_manage';

// CommMate: Updated tab permissions - agents need specific permissions for extended tabs
export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  me: {
    count: 'mineCount',
    // "Mine" tab is always visible to all agents and admins
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  },
  unassigned: {
    count: 'unAssignedCount',
    // "Unassigned" tab requires admin or specific conversation permissions
    permissions: [
      'administrator',
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_UNASSIGNED_PERMISSIONS,
    ],
  },
  all: {
    count: 'allCount',
    // "All" tab requires admin or specific conversation permissions
    permissions: [
      'administrator',
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_PARTICIPATING_PERMISSIONS,
    ],
  },
};
