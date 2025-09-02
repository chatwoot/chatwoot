import { computed } from 'vue';
import { useMapGetter } from './store';

export function useRbac() {
  const currentUser = useMapGetter('getCurrentUser');
  const currentAccountId = useMapGetter('getCurrentAccountId');
  
  const currentAccountUser = computed(() => {
    if (!currentUser.value?.account_users || !currentAccountId.value) {
      return null;
    }
    return currentUser.value.account_users.find(au => au.account_id === currentAccountId.value);
  });

  const userRole = computed(() => {
    return currentAccountUser.value?.role || 'agent';
  });

  const customRole = computed(() => {
    return currentAccountUser.value?.custom_role;
  });

  const effectivePermissions = computed(() => {
    const accountUser = currentAccountUser.value;
    if (!accountUser) return [];

    // Base permissions from role
    let permissions = [];
    
    switch (accountUser.role) {
      case 'owner':
        permissions = getAllPermissions();
        break;
      case 'administrator':
        permissions = getAllPermissions().filter(p => p !== 'feature_flags_manage');
        break;
      case 'agent':
        permissions = getAgentPermissions();
        break;
      case 'finance':
        permissions = getFinancePermissions();
        break;
      case 'support':
        permissions = getSupportPermissions();
        break;
    }

    // Add custom role permissions
    if (accountUser.custom_role?.permissions) {
      permissions = [...permissions, ...accountUser.custom_role.permissions];
    }

    // Apply individual overrides if they exist
    if (accountUser.permissions_override) {
      const granted = accountUser.permissions_override.granted || [];
      const revoked = accountUser.permissions_override.revoked || [];
      
      permissions = [...permissions, ...granted].filter(p => !revoked.includes(p));
    }

    // Remove duplicates
    return [...new Set(permissions)];
  });

  const roleHierarchy = computed(() => {
    const accountUser = currentAccountUser.value;
    if (!accountUser) return 0;

    if (accountUser.custom_role?.role_hierarchy !== undefined) {
      return accountUser.custom_role.role_hierarchy;
    }

    const hierarchyMap = {
      'owner': 150,
      'administrator': 100,
      'finance': 75,
      'agent': 50,
      'support': 25
    };

    return hierarchyMap[accountUser.role] || 0;
  });

  // Permission check functions
  const hasPermission = (permission) => {
    if (!currentAccountUser.value) return false;
    
    // Owner and admin have most permissions
    if (userRole.value === 'owner') return true;
    if (userRole.value === 'administrator' && permission !== 'feature_flags_manage') return true;
    
    return effectivePermissions.value.includes(permission);
  };

  const hasAnyPermission = (permissions) => {
    return permissions.some(permission => hasPermission(permission));
  };

  const hasAllPermissions = (permissions) => {
    return permissions.every(permission => hasPermission(permission));
  };

  const canManageUser = (targetUser) => {
    if (!currentAccountUser.value || !targetUser) return false;
    
    const targetHierarchy = getTargetUserHierarchy(targetUser);
    return roleHierarchy.value > targetHierarchy;
  };

  const canAssignRole = (targetRole) => {
    if (!hasPermission('role_assign')) return false;
    
    const targetHierarchy = typeof targetRole === 'string' 
      ? getRoleHierarchy(targetRole)
      : targetRole.role_hierarchy || 0;
      
    return roleHierarchy.value > targetHierarchy;
  };

  // UI Guard functions for specific features
  const canViewConversations = () => {
    return hasAnyPermission(['conversation_view_all', 'conversation_view_assigned', 'conversation_view_participating']);
  };

  const canManageConversations = () => {
    return hasAnyPermission(['conversation_manage_all', 'conversation_manage_assigned']);
  };

  const canViewContacts = () => {
    return hasPermission('contact_view');
  };

  const canManageContacts = () => {
    return hasAnyPermission(['contact_create', 'contact_update', 'contact_delete']);
  };

  const canViewTeam = () => {
    return hasPermission('team_view');
  };

  const canManageTeam = () => {
    return hasAnyPermission(['team_invite', 'team_manage']);
  };

  const canViewReports = () => {
    return hasPermission('report_view');
  };

  const canViewAdvancedReports = () => {
    return hasPermission('report_advanced');
  };

  const canViewBilling = () => {
    return hasAnyPermission(['billing_view', 'billing_manage']);
  };

  const canManageBilling = () => {
    return hasPermission('billing_manage');
  };

  const canViewSettings = () => {
    return hasAnyPermission([
      'settings_account', 'settings_channels', 'settings_integrations',
      'settings_webhooks', 'settings_automation', 'settings_security', 'settings_advanced'
    ]);
  };

  const canManageSettings = (settingType = 'account') => {
    return hasPermission(`settings_${settingType}`);
  };

  const canViewKnowledgeBase = () => {
    return hasPermission('kb_view');
  };

  const canManageKnowledgeBase = () => {
    return hasAnyPermission(['kb_article_create', 'kb_article_edit', 'kb_article_delete', 'kb_portal_manage']);
  };

  const canViewChannels = () => {
    return hasPermission('channel_view');
  };

  const canManageChannels = () => {
    return hasAnyPermission(['channel_create', 'channel_configure', 'channel_delete']);
  };

  const canViewAuditLogs = () => {
    return hasPermission('audit_log_view');
  };

  const canManageFeatureFlags = () => {
    return hasPermission('feature_flags_manage');
  };

  // Role display helpers
  const roleDisplayName = computed(() => {
    if (customRole.value?.name) {
      return customRole.value.name;
    }
    
    const roleNames = {
      'owner': 'Owner',
      'administrator': 'Administrator',
      'finance': 'Finance',
      'agent': 'Agent',
      'support': 'Support'
    };
    
    return roleNames[userRole.value] || userRole.value;
  });

  const roleColor = computed(() => {
    if (customRole.value?.role_color) {
      return customRole.value.role_color;
    }
    
    const roleColors = {
      'owner': '#8127E8',
      'administrator': '#FF6600',
      'finance': '#10B981',
      'agent': '#3B82F6',
      'support': '#8B5CF6'
    };
    
    return roleColors[userRole.value] || '#6B7280';
  });

  const isPrimaryOwner = computed(() => {
    return currentAccountUser.value?.is_primary_owner === true;
  });

  // Helper functions
  function getAllPermissions() {
    return [
      // Conversations
      'conversation_view_all', 'conversation_view_assigned', 'conversation_view_participating',
      'conversation_manage_all', 'conversation_manage_assigned', 'conversation_assign',
      'conversation_transfer', 'conversation_resolve', 'conversation_reopen',
      'conversation_private_notes', 'conversation_export',
      
      // Contacts
      'contact_view', 'contact_create', 'contact_update', 'contact_delete',
      'contact_merge', 'contact_export', 'contact_import', 'contact_custom_attributes',
      
      // Team
      'team_view', 'team_invite', 'team_manage', 'user_profile_update',
      'role_assign', 'role_create', 'role_manage',
      
      // Reports
      'report_view', 'report_advanced', 'report_export', 'report_custom',
      'analytics_view', 'analytics_export',
      
      // Billing
      'billing_view', 'billing_manage', 'invoice_view', 'invoice_download',
      'payment_methods', 'subscription_manage', 'usage_view',
      
      // Settings
      'settings_account', 'settings_channels', 'settings_integrations',
      'settings_webhooks', 'settings_automation', 'settings_security', 'settings_advanced',
      
      // Knowledge Base
      'kb_view', 'kb_article_create', 'kb_article_edit', 'kb_article_delete',
      'kb_category_manage', 'kb_portal_manage', 'kb_publish',
      
      // Channels
      'channel_view', 'channel_create', 'channel_configure', 'channel_delete',
      'integration_manage', 'webhook_manage',
      
      // System
      'audit_log_view', 'system_info_view', 'feature_flags_view', 'feature_flags_manage'
    ];
  }

  function getAgentPermissions() {
    return [
      'conversation_view_assigned', 'conversation_view_participating',
      'conversation_manage_assigned', 'conversation_resolve', 'conversation_reopen',
      'conversation_private_notes', 'contact_view', 'contact_update',
      'contact_custom_attributes', 'team_view', 'user_profile_update',
      'report_view', 'kb_view', 'kb_article_create', 'kb_article_edit', 'channel_view'
    ];
  }

  function getFinancePermissions() {
    return [
      'team_view', 'report_view', 'report_advanced', 'report_export', 'report_custom',
      'analytics_view', 'analytics_export', 'billing_view', 'billing_manage',
      'invoice_view', 'invoice_download', 'payment_methods', 'subscription_manage',
      'usage_view', 'settings_account'
    ];
  }

  function getSupportPermissions() {
    return [
      'conversation_view_assigned', 'conversation_view_participating',
      'conversation_manage_assigned', 'conversation_resolve', 'contact_view',
      'team_view', 'user_profile_update', 'report_view', 'kb_view',
      'kb_article_create', 'kb_article_edit', 'channel_view'
    ];
  }

  function getTargetUserHierarchy(targetUser) {
    if (targetUser.custom_role?.role_hierarchy !== undefined) {
      return targetUser.custom_role.role_hierarchy;
    }
    return getRoleHierarchy(targetUser.role);
  }

  function getRoleHierarchy(role) {
    const hierarchyMap = {
      'owner': 150,
      'administrator': 100,
      'finance': 75,
      'agent': 50,
      'support': 25
    };
    return hierarchyMap[role] || 0;
  }

  return {
    // User info
    currentAccountUser,
    userRole,
    customRole,
    effectivePermissions,
    roleHierarchy,
    roleDisplayName,
    roleColor,
    isPrimaryOwner,
    
    // Permission checking
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
    canManageUser,
    canAssignRole,
    
    // Feature-specific permissions
    canViewConversations,
    canManageConversations,
    canViewContacts,
    canManageContacts,
    canViewTeam,
    canManageTeam,
    canViewReports,
    canViewAdvancedReports,
    canViewBilling,
    canManageBilling,
    canViewSettings,
    canManageSettings,
    canViewKnowledgeBase,
    canManageKnowledgeBase,
    canViewChannels,
    canManageChannels,
    canViewAuditLogs,
    canManageFeatureFlags
  };
}