# == Schema Information
#
# Table name: custom_roles
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  permissions :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_custom_roles_on_account_id  (account_id)
#
#

# Enhanced RBAC System for WeaveSmart Chat
# Comprehensive permissions system with granular access control

class CustomRole < ApplicationRecord
  belongs_to :account
  has_many :account_users, dependent: :nullify

  # System role types
  SYSTEM_ROLE_TYPES = %w[owner admin agent finance support].freeze
  
  # Role hierarchy levels
  ROLE_HIERARCHY = {
    'owner' => 150,
    'admin' => 100, 
    'finance' => 75,
    'agent' => 50,
    'support' => 25,
    'custom' => 0
  }.freeze

  # Comprehensive permissions list
  PERMISSIONS = %w[
    conversation_view_all
    conversation_view_assigned
    conversation_view_participating
    conversation_manage_all
    conversation_manage_assigned
    conversation_assign
    conversation_transfer
    conversation_resolve
    conversation_reopen
    conversation_private_notes
    conversation_export
    
    contact_view
    contact_create
    contact_update
    contact_delete
    contact_merge
    contact_export
    contact_import
    contact_custom_attributes
    
    team_view
    team_invite
    team_manage
    user_profile_update
    role_assign
    role_create
    role_manage
    
    report_view
    report_advanced
    report_export
    report_custom
    analytics_view
    analytics_export
    
    billing_view
    billing_manage
    invoice_view
    invoice_download
    payment_methods
    subscription_manage
    usage_view
    
    settings_account
    settings_channels
    settings_integrations
    settings_webhooks
    settings_automation
    settings_security
    settings_advanced
    
    kb_view
    kb_article_create
    kb_article_edit
    kb_article_delete
    kb_category_manage
    kb_portal_manage
    kb_publish
    
    channel_view
    channel_create
    channel_configure
    channel_delete
    integration_manage
    webhook_manage
    
    audit_log_view
    system_info_view
    feature_flags_view
    feature_flags_manage
  ].freeze

  # Default permission sets for system roles
  DEFAULT_PERMISSIONS = {
    'owner' => PERMISSIONS, # All permissions
    'admin' => PERMISSIONS - %w[feature_flags_manage], # All except feature flag management
    'agent' => %w[
      conversation_view_assigned
      conversation_view_participating
      conversation_manage_assigned
      conversation_resolve
      conversation_reopen
      conversation_private_notes
      contact_view
      contact_update
      contact_custom_attributes
      team_view
      user_profile_update
      report_view
      kb_view
      kb_article_create
      kb_article_edit
      channel_view
    ],
    'finance' => %w[
      team_view
      report_view
      report_advanced
      report_export
      report_custom
      analytics_view
      analytics_export
      billing_view
      billing_manage
      invoice_view
      invoice_download
      payment_methods
      subscription_manage
      usage_view
      settings_account
    ],
    'support' => %w[
      conversation_view_assigned
      conversation_view_participating
      conversation_manage_assigned
      conversation_resolve
      contact_view
      team_view
      user_profile_update
      report_view
      kb_view
      kb_article_create
      kb_article_edit
      channel_view
    ]
  }.freeze

  validates :name, presence: true
  validates :permissions, inclusion: { in: PERMISSIONS }
  validates :role_type, inclusion: { in: SYSTEM_ROLE_TYPES }, allow_nil: true
  validates :role_hierarchy, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_defaults
  before_save :ensure_role_hierarchy

  scope :system_roles, -> { where(is_system_role: true) }
  scope :custom_roles, -> { where(is_system_role: false) }
  scope :by_hierarchy, -> { order(role_hierarchy: :desc) }

  def system_role?
    is_system_role?
  end

  def custom_role?
    !is_system_role?
  end

  def hierarchy_level
    role_hierarchy || 0
  end

  def can_manage_role?(other_role)
    # Can only manage roles with lower hierarchy
    hierarchy_level > (other_role.is_a?(CustomRole) ? other_role.hierarchy_level : 0)
  end

  def has_permission?(permission)
    return false unless permission
    permissions.include?(permission.to_s)
  end

  def has_any_permission?(permission_list)
    return false unless permission_list.is_a?(Array)
    (permissions & permission_list.map(&:to_s)).any?
  end

  def has_all_permissions?(permission_list)
    return false unless permission_list.is_a?(Array)
    (permission_list.map(&:to_s) - permissions).empty?
  end

  def permission_categories
    # Group permissions by category for UI display
    {
      'Conversations' => permissions.select { |p| p.start_with?('conversation_') },
      'Contacts' => permissions.select { |p| p.start_with?('contact_') },
      'Team Management' => permissions.select { |p| p.start_with?('team_', 'user_', 'role_') },
      'Reporting' => permissions.select { |p| p.start_with?('report_', 'analytics_') },
      'Billing' => permissions.select { |p| p.start_with?('billing_', 'invoice_', 'payment_', 'subscription_', 'usage_') },
      'Settings' => permissions.select { |p| p.start_with?('settings_') },
      'Knowledge Base' => permissions.select { |p| p.start_with?('kb_') },
      'Channels' => permissions.select { |p| p.start_with?('channel_', 'integration_', 'webhook_') },
      'System' => permissions.select { |p| p.start_with?('audit_', 'system_', 'feature_') }
    }.reject { |_, perms| perms.empty? }
  end

  def self.create_system_roles!(account)
    # Create default system roles for an account
    SYSTEM_ROLE_TYPES.each do |role_type|
      next if account.custom_roles.system_roles.exists?(role_type: role_type)

      create!(
        account: account,
        name: role_type.humanize,
        description: "System #{role_type} role with default permissions",
        permissions: DEFAULT_PERMISSIONS[role_type] || [],
        role_type: role_type,
        is_system_role: true,
        role_hierarchy: ROLE_HIERARCHY[role_type] || 0,
        role_color: default_role_color(role_type)
      )
    end
  end

  def self.default_role_color(role_type)
    {
      'owner' => '#8127E8',      # Primary purple
      'admin' => '#FF6600',      # Accent orange
      'finance' => '#10B981',    # Green
      'agent' => '#3B82F6',      # Blue
      'support' => '#8B5CF6'     # Purple
    }[role_type] || '#6B7280'    # Gray default
  end

  private

  def set_defaults
    if role_type.present? && is_system_role?
      self.permissions ||= DEFAULT_PERMISSIONS[role_type] || []
      self.role_hierarchy ||= ROLE_HIERARCHY[role_type] || 0
      self.role_color ||= self.class.default_role_color(role_type)
    end

    self.role_hierarchy ||= 0
  end

  def ensure_role_hierarchy
    if role_type.present? && ROLE_HIERARCHY[role_type]
      self.role_hierarchy = ROLE_HIERARCHY[role_type]
    end
  end
end
