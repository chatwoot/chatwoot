class RbacPolicy < ApplicationPolicy
  # Enhanced RBAC Policy for WeaveSmart Chat
  # Provides fine-grained permission checking based on user roles and custom permissions
  
  class Scope
    def initialize(account_user, scope)
      @account_user = account_user
      @scope = scope
    end

    def resolve
      @scope
    end

    private

    attr_reader :account_user, :scope
  end

  def initialize(account_user, record)
    @account_user = account_user
    @record = record
    @account = account_user&.account
  end

  # Conversation permissions
  def view_conversation?
    return true if owner_or_admin?
    return true if @account_user.has_permission?('conversation_view_all')
    return true if @account_user.has_permission?('conversation_view_assigned') && assigned_to_user?
    return true if @account_user.has_permission?('conversation_view_participating') && participating_in_conversation?
    false
  end

  def manage_conversation?
    return true if owner_or_admin?
    return true if @account_user.has_permission?('conversation_manage_all')
    return true if @account_user.has_permission?('conversation_manage_assigned') && assigned_to_user?
    false
  end

  def assign_conversation?
    return true if owner_or_admin?
    @account_user.has_permission?('conversation_assign')
  end

  def transfer_conversation?
    return true if owner_or_admin?
    @account_user.has_permission?('conversation_transfer')
  end

  def resolve_conversation?
    return true if owner_or_admin?
    return true if @account_user.has_permission?('conversation_resolve') && can_access_conversation?
    false
  end

  def add_private_note?
    return true if owner_or_admin?
    return true if @account_user.has_permission?('conversation_private_notes') && can_access_conversation?
    false
  end

  def export_conversation?
    return true if owner_or_admin?
    @account_user.has_permission?('conversation_export')
  end

  # Contact permissions
  def view_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_view')
  end

  def create_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_create')
  end

  def update_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_update')
  end

  def delete_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_delete')
  end

  def merge_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_merge')
  end

  def export_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_export')
  end

  def import_contact?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_import')
  end

  def manage_contact_custom_attributes?
    return true if owner_or_admin?
    @account_user.has_permission?('contact_custom_attributes')
  end

  # Team management permissions
  def view_team?
    return true if owner_or_admin?
    @account_user.has_permission?('team_view')
  end

  def invite_team_member?
    return true if owner_or_admin?
    @account_user.has_permission?('team_invite')
  end

  def manage_team?
    return true if owner_or_admin?
    @account_user.has_permission?('team_manage')
  end

  def update_user_profile?
    # Users can always update their own profile
    return true if @record == @account_user.user
    return true if owner_or_admin?
    @account_user.has_permission?('user_profile_update')
  end

  def assign_role?
    return false unless @account_user.has_permission?('role_assign')
    # Can only assign roles with lower hierarchy
    @account_user.can_assign_role?(@record)
  end

  def create_role?
    return true if owner_or_admin?
    @account_user.has_permission?('role_create')
  end

  def manage_role?
    return true if owner_or_admin?
    return false unless @account_user.has_permission?('role_manage')
    # Can only manage roles with lower hierarchy
    if @record.is_a?(CustomRole)
      @account_user.role_hierarchy > @record.hierarchy_level
    else
      true
    end
  end

  # Reporting permissions
  def view_reports?
    return true if owner_or_admin?
    @account_user.has_permission?('report_view')
  end

  def view_advanced_reports?
    return true if owner_or_admin?
    @account_user.has_permission?('report_advanced')
  end

  def export_reports?
    return true if owner_or_admin?
    @account_user.has_permission?('report_export')
  end

  def create_custom_reports?
    return true if owner_or_admin?
    @account_user.has_permission?('report_custom')
  end

  def view_analytics?
    return true if owner_or_admin?
    @account_user.has_permission?('analytics_view')
  end

  def export_analytics?
    return true if owner_or_admin?
    @account_user.has_permission?('analytics_export')
  end

  # Billing permissions
  def view_billing?
    return true if @account_user.owner?
    return true if @account_user.finance?
    @account_user.has_permission?('billing_view')
  end

  def manage_billing?
    return true if @account_user.owner?
    return true if @account_user.finance?
    @account_user.has_permission?('billing_manage')
  end

  def view_invoices?
    return true if owner_or_admin?
    return true if @account_user.finance?
    @account_user.has_permission?('invoice_view')
  end

  def download_invoices?
    return true if owner_or_admin?
    return true if @account_user.finance?
    @account_user.has_permission?('invoice_download')
  end

  def manage_payment_methods?
    return true if @account_user.owner?
    return true if @account_user.finance?
    @account_user.has_permission?('payment_methods')
  end

  def manage_subscription?
    return true if @account_user.owner?
    return true if @account_user.finance?
    @account_user.has_permission?('subscription_manage')
  end

  def view_usage?
    return true if owner_or_admin?
    return true if @account_user.finance?
    @account_user.has_permission?('usage_view')
  end

  # Settings permissions
  def manage_account_settings?
    return true if owner_or_admin?
    @account_user.has_permission?('settings_account')
  end

  def manage_channel_settings?
    return true if owner_or_admin?
    @account_user.has_permission?('settings_channels')
  end

  def manage_integration_settings?
    return true if owner_or_admin?
    @account_user.has_permission?('settings_integrations')
  end

  def manage_webhook_settings?
    return true if owner_or_admin?
    @account_user.has_permission?('settings_webhooks')
  end

  def manage_automation_settings?
    return true if owner_or_admin?
    @account_user.has_permission?('settings_automation')
  end

  def manage_security_settings?
    return true if @account_user.owner?
    return true if @account_user.administrator?
    @account_user.has_permission?('settings_security')
  end

  def manage_advanced_settings?
    return true if @account_user.owner?
    @account_user.has_permission?('settings_advanced')
  end

  # Knowledge Base permissions
  def view_knowledge_base?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_view')
  end

  def create_kb_article?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_article_create')
  end

  def edit_kb_article?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_article_edit')
  end

  def delete_kb_article?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_article_delete')
  end

  def manage_kb_categories?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_category_manage')
  end

  def manage_kb_portals?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_portal_manage')
  end

  def publish_kb_content?
    return true if owner_or_admin?
    @account_user.has_permission?('kb_publish')
  end

  # Channel permissions
  def view_channels?
    return true if owner_or_admin?
    @account_user.has_permission?('channel_view')
  end

  def create_channel?
    return true if owner_or_admin?
    @account_user.has_permission?('channel_create')
  end

  def configure_channel?
    return true if owner_or_admin?
    @account_user.has_permission?('channel_configure')
  end

  def delete_channel?
    return true if owner_or_admin?
    @account_user.has_permission?('channel_delete')
  end

  def manage_integrations?
    return true if owner_or_admin?
    @account_user.has_permission?('integration_manage')
  end

  def manage_webhooks?
    return true if owner_or_admin?
    @account_user.has_permission?('webhook_manage')
  end

  # System permissions
  def view_audit_logs?
    return true if owner_or_admin?
    @account_user.has_permission?('audit_log_view')
  end

  def view_system_info?
    return true if owner_or_admin?
    @account_user.has_permission?('system_info_view')
  end

  def view_feature_flags?
    return true if owner_or_admin?
    @account_user.has_permission?('feature_flags_view')
  end

  def manage_feature_flags?
    # Only owners can manage feature flags
    @account_user.owner?
  end

  private

  attr_reader :account_user, :record, :account

  def owner_or_admin?
    @account_user.owner? || @account_user.administrator?
  end

  def assigned_to_user?
    return false unless @record.respond_to?(:assignee)
    @record.assignee == @account_user.user
  end

  def participating_in_conversation?
    return false unless @record.respond_to?(:messages)
    @record.messages.exists?(sender: @account_user.user)
  end

  def can_access_conversation?
    view_conversation?
  end

  # Helper method to check multiple permissions at once
  def has_any_permission?(permissions)
    @account_user.has_any_permission?(permissions)
  end

  def has_all_permissions?(permissions)
    permissions.all? { |permission| @account_user.has_permission?(permission) }
  end
end