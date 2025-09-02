class RbacService
  # Service class for RBAC operations and utilities
  # Provides centralized permission checking and role management
  
  def self.check_permission(account_user, permission, resource = nil)
    return false unless account_user.is_a?(AccountUser)
    
    policy = RbacPolicy.new(account_user, resource)
    
    case permission.to_s
    when 'view_conversation' then policy.view_conversation?
    when 'manage_conversation' then policy.manage_conversation?
    when 'assign_conversation' then policy.assign_conversation?
    when 'transfer_conversation' then policy.transfer_conversation?
    when 'resolve_conversation' then policy.resolve_conversation?
    when 'add_private_note' then policy.add_private_note?
    when 'export_conversation' then policy.export_conversation?
    
    when 'view_contact' then policy.view_contact?
    when 'create_contact' then policy.create_contact?
    when 'update_contact' then policy.update_contact?
    when 'delete_contact' then policy.delete_contact?
    when 'merge_contact' then policy.merge_contact?
    when 'export_contact' then policy.export_contact?
    when 'import_contact' then policy.import_contact?
    when 'manage_contact_custom_attributes' then policy.manage_contact_custom_attributes?
    
    when 'view_team' then policy.view_team?
    when 'invite_team_member' then policy.invite_team_member?
    when 'manage_team' then policy.manage_team?
    when 'update_user_profile' then policy.update_user_profile?
    when 'assign_role' then policy.assign_role?
    when 'create_role' then policy.create_role?
    when 'manage_role' then policy.manage_role?
    
    when 'view_reports' then policy.view_reports?
    when 'view_advanced_reports' then policy.view_advanced_reports?
    when 'export_reports' then policy.export_reports?
    when 'create_custom_reports' then policy.create_custom_reports?
    when 'view_analytics' then policy.view_analytics?
    when 'export_analytics' then policy.export_analytics?
    
    when 'view_billing' then policy.view_billing?
    when 'manage_billing' then policy.manage_billing?
    when 'view_invoices' then policy.view_invoices?
    when 'download_invoices' then policy.download_invoices?
    when 'manage_payment_methods' then policy.manage_payment_methods?
    when 'manage_subscription' then policy.manage_subscription?
    when 'view_usage' then policy.view_usage?
    
    when 'manage_account_settings' then policy.manage_account_settings?
    when 'manage_channel_settings' then policy.manage_channel_settings?
    when 'manage_integration_settings' then policy.manage_integration_settings?
    when 'manage_webhook_settings' then policy.manage_webhook_settings?
    when 'manage_automation_settings' then policy.manage_automation_settings?
    when 'manage_security_settings' then policy.manage_security_settings?
    when 'manage_advanced_settings' then policy.manage_advanced_settings?
    
    when 'view_knowledge_base' then policy.view_knowledge_base?
    when 'create_kb_article' then policy.create_kb_article?
    when 'edit_kb_article' then policy.edit_kb_article?
    when 'delete_kb_article' then policy.delete_kb_article?
    when 'manage_kb_categories' then policy.manage_kb_categories?
    when 'manage_kb_portals' then policy.manage_kb_portals?
    when 'publish_kb_content' then policy.publish_kb_content?
    
    when 'view_channels' then policy.view_channels?
    when 'create_channel' then policy.create_channel?
    when 'configure_channel' then policy.configure_channel?
    when 'delete_channel' then policy.delete_channel?
    when 'manage_integrations' then policy.manage_integrations?
    when 'manage_webhooks' then policy.manage_webhooks?
    
    when 'view_audit_logs' then policy.view_audit_logs?
    when 'view_system_info' then policy.view_system_info?
    when 'view_feature_flags' then policy.view_feature_flags?
    when 'manage_feature_flags' then policy.manage_feature_flags?
    
    else
      # Fall back to direct permission check
      account_user.has_permission?(permission)
    end
  end
  
  def self.user_permissions(account_user)
    # Return all effective permissions for a user
    return [] unless account_user.is_a?(AccountUser)
    account_user.effective_permissions
  end
  
  def self.role_hierarchy_for(account_user)
    return 0 unless account_user.is_a?(AccountUser)
    account_user.role_hierarchy
  end
  
  def self.can_user_manage_user?(manager, target_user)
    return false unless manager.is_a?(AccountUser) && target_user.is_a?(AccountUser)
    return false unless manager.account_id == target_user.account_id
    
    manager.can_manage_user?(target_user)
  end
  
  def self.available_roles_for_user(account_user)
    # Return roles that a user can assign to others
    return [] unless account_user.is_a?(AccountUser)
    return [] unless account_user.has_permission?('role_assign')
    
    account = account_user.account
    available_roles = []
    
    # System roles
    CustomRole::SYSTEM_ROLE_TYPES.each do |role_type|
      role_hierarchy = CustomRole::ROLE_HIERARCHY[role_type] || 0
      if account_user.role_hierarchy > role_hierarchy
        available_roles << {
          type: 'system',
          role: role_type,
          name: role_type.humanize,
          hierarchy: role_hierarchy
        }
      end
    end
    
    # Custom roles
    account.custom_roles.custom_roles.each do |custom_role|
      if account_user.can_manage_role?(custom_role)
        available_roles << {
          type: 'custom',
          role: custom_role,
          name: custom_role.name,
          hierarchy: custom_role.hierarchy_level
        }
      end
    end
    
    available_roles.sort_by { |role| -role[:hierarchy] }
  end
  
  def self.permission_categories
    # Return all permission categories for UI display
    {
      'Conversations' => CustomRole::PERMISSIONS.select { |p| p.start_with?('conversation_') },
      'Contacts' => CustomRole::PERMISSIONS.select { |p| p.start_with?('contact_') },
      'Team Management' => CustomRole::PERMISSIONS.select { |p| p.start_with?('team_', 'user_', 'role_') },
      'Reporting' => CustomRole::PERMISSIONS.select { |p| p.start_with?('report_', 'analytics_') },
      'Billing' => CustomRole::PERMISSIONS.select { |p| p.start_with?('billing_', 'invoice_', 'payment_', 'subscription_', 'usage_') },
      'Settings' => CustomRole::PERMISSIONS.select { |p| p.start_with?('settings_') },
      'Knowledge Base' => CustomRole::PERMISSIONS.select { |p| p.start_with?('kb_') },
      'Channels' => CustomRole::PERMISSIONS.select { |p| p.start_with?('channel_', 'integration_', 'webhook_') },
      'System' => CustomRole::PERMISSIONS.select { |p| p.start_with?('audit_', 'system_', 'feature_') }
    }.reject { |_, perms| perms.empty? }
  end
  
  def self.permission_description(permission)
    # Human-readable descriptions for permissions
    descriptions = {
      'conversation_view_all' => 'View all conversations in the account',
      'conversation_view_assigned' => 'View conversations assigned to them',
      'conversation_view_participating' => 'View conversations they are participating in',
      'conversation_manage_all' => 'Manage all conversations (assign, transfer, resolve)',
      'conversation_manage_assigned' => 'Manage conversations assigned to them',
      'conversation_assign' => 'Assign conversations to team members',
      'conversation_transfer' => 'Transfer conversations between team members',
      'conversation_resolve' => 'Resolve conversations',
      'conversation_reopen' => 'Reopen resolved conversations',
      'conversation_private_notes' => 'Add private notes to conversations',
      'conversation_export' => 'Export conversation data',
      
      'contact_view' => 'View contact information',
      'contact_create' => 'Create new contacts',
      'contact_update' => 'Update contact details',
      'contact_delete' => 'Delete contacts',
      'contact_merge' => 'Merge duplicate contacts',
      'contact_export' => 'Export contact data',
      'contact_import' => 'Import contact data',
      'contact_custom_attributes' => 'Manage contact custom attributes',
      
      'team_view' => 'View team members and their information',
      'team_invite' => 'Invite new team members',
      'team_manage' => 'Full team management capabilities',
      'user_profile_update' => 'Update user profiles',
      'role_assign' => 'Assign roles to team members',
      'role_create' => 'Create new custom roles',
      'role_manage' => 'Manage existing roles and permissions',
      
      'report_view' => 'View basic reports and statistics',
      'report_advanced' => 'Access advanced analytics and reports',
      'report_export' => 'Export report data',
      'report_custom' => 'Create custom reports',
      'analytics_view' => 'View analytics dashboard',
      'analytics_export' => 'Export analytics data',
      
      'billing_view' => 'View billing information and subscription details',
      'billing_manage' => 'Manage billing settings and subscriptions',
      'invoice_view' => 'View invoices',
      'invoice_download' => 'Download invoices',
      'payment_methods' => 'Manage payment methods',
      'subscription_manage' => 'Manage subscription plans',
      'usage_view' => 'View usage metrics and limits',
      
      'settings_account' => 'Manage account settings',
      'settings_channels' => 'Configure communication channels',
      'settings_integrations' => 'Manage integrations',
      'settings_webhooks' => 'Configure webhooks',
      'settings_automation' => 'Manage automation rules',
      'settings_security' => 'Manage security settings',
      'settings_advanced' => 'Access advanced configuration options',
      
      'kb_view' => 'View knowledge base content',
      'kb_article_create' => 'Create knowledge base articles',
      'kb_article_edit' => 'Edit knowledge base articles',
      'kb_article_delete' => 'Delete knowledge base articles',
      'kb_category_manage' => 'Manage knowledge base categories',
      'kb_portal_manage' => 'Manage knowledge base portals',
      'kb_publish' => 'Publish knowledge base content',
      
      'channel_view' => 'View channel information',
      'channel_create' => 'Create new communication channels',
      'channel_configure' => 'Configure existing channels',
      'channel_delete' => 'Delete channels',
      'integration_manage' => 'Manage third-party integrations',
      'webhook_manage' => 'Manage webhook configurations',
      
      'audit_log_view' => 'View audit logs',
      'system_info_view' => 'View system information',
      'feature_flags_view' => 'View feature flag settings',
      'feature_flags_manage' => 'Manage feature flags (Owner only)'
    }
    
    descriptions[permission.to_s] || permission.to_s.humanize
  end
  
  def self.setup_default_roles_for_account(account)
    # Create default system roles for a new account
    CustomRole.create_system_roles!(account)
  end
  
  def self.audit_permission_change(account_user, action, details = {})
    # Log permission changes for audit trail
    Rails.logger.info({
      event: 'rbac_permission_change',
      account_id: account_user.account_id,
      user_id: account_user.user_id,
      action: action,
      details: details,
      timestamp: Time.current.iso8601
    }.to_json)
  end
end