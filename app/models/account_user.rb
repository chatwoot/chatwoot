# == Schema Information
#
# Table name: account_users
#
#  id                       :bigint           not null, primary key
#  active_at                :datetime
#  auto_offline             :boolean          default(TRUE), not null
#  availability             :integer          default("online"), not null
#  role                     :integer          default("agent")
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint
#  agent_capacity_policy_id :bigint
#  custom_role_id           :bigint
#  inviter_id               :bigint
#  user_id                  :bigint
#
# Indexes
#
#  index_account_users_on_account_id                (account_id)
#  index_account_users_on_agent_capacity_policy_id  (agent_capacity_policy_id)
#  index_account_users_on_custom_role_id            (custom_role_id)
#  index_account_users_on_user_id                   (user_id)
#  uniq_user_id_per_account_id                      (account_id,user_id) UNIQUE
#

class AccountUser < ApplicationRecord
  include AvailabilityStatusable

  belongs_to :account
  belongs_to :user
  belongs_to :inviter, class_name: 'User', optional: true

  enum role: { agent: 0, administrator: 1, owner: 2, finance: 3, support: 4 }
  enum availability: { online: 0, offline: 1, busy: 2 }

  accepts_nested_attributes_for :account

  after_create_commit :notify_creation, :create_notification_setting
  after_destroy :notify_deletion, :remove_user_from_account
  after_save :update_presence_in_redis, if: :saved_change_to_availability?

  validates :user_id, uniqueness: { scope: :account_id }

  def create_notification_setting
    setting = user.notification_settings.new(account_id: account.id)
    setting.selected_email_flags = [:email_conversation_assignment]
    setting.selected_push_flags = [:push_conversation_assignment]
    setting.save!
  end

  def remove_user_from_account
    ::Agents::DestroyJob.perform_later(account, user)
  end

  belongs_to :custom_role, optional: true

  # Add role hierarchy and permission methods
  def role_hierarchy
    return custom_role.hierarchy_level if custom_role&.hierarchy_level
    return role_hierarchy_value if respond_to?(:role_hierarchy_value)
    
    # Default hierarchy based on role
    case role
    when 'owner' then 150
    when 'administrator' then 100
    when 'finance' then 75
    when 'agent' then 50
    when 'support' then 25
    else 0
    end
  end

  def effective_permissions
    # Start with base role permissions
    base_permissions = base_role_permissions
    
    # Add custom role permissions if assigned
    if custom_role
      base_permissions += custom_role.permissions
    end
    
    # Add any individual permission overrides
    if respond_to?(:permissions_override) && permissions_override.present?
      granted = permissions_override['granted'] || []
      revoked = permissions_override['revoked'] || []
      
      base_permissions += granted
      base_permissions -= revoked
    end
    
    base_permissions.uniq
  end

  def permissions
    # Legacy method for backwards compatibility
    case role
    when 'owner', 'administrator'
      ['administrator'] + effective_permissions
    else
      ['agent'] + effective_permissions
    end
  end

  def has_permission?(permission)
    return true if owner? || (administrator? && permission != 'feature_flags_manage')
    
    effective_permissions.include?(permission.to_s)
  end

  def has_any_permission?(permission_list)
    return true if owner?
    return false unless permission_list.is_a?(Array)
    
    (effective_permissions & permission_list.map(&:to_s)).any?
  end

  def can_manage_user?(other_account_user)
    # Can only manage users with lower hierarchy
    role_hierarchy > other_account_user.role_hierarchy
  end

  def can_assign_role?(role_or_custom_role)
    return false unless has_permission?('role_assign')
    
    if role_or_custom_role.is_a?(CustomRole)
      # Can only assign roles with lower hierarchy
      role_hierarchy > role_or_custom_role.hierarchy_level
    else
      # For string roles, check hierarchy
      target_hierarchy = case role_or_custom_role.to_s
                        when 'owner' then 150
                        when 'administrator' then 100
                        when 'finance' then 75
                        when 'agent' then 50
                        when 'support' then 25
                        else 0
                        end
      role_hierarchy > target_hierarchy
    end
  end

  def primary_owner?
    owner? && (respond_to?(:is_primary_owner) ? is_primary_owner : false)
  end

  def role_display_name
    if custom_role
      custom_role.name
    else
      role.humanize
    end
  end

  def role_color
    if custom_role&.role_color
      custom_role.role_color
    else
      default_role_color
    end
  end

  private

  def base_role_permissions
    case role
    when 'owner'
      CustomRole::PERMISSIONS
    when 'administrator' 
      CustomRole::PERMISSIONS - %w[feature_flags_manage]
    when 'agent'
      CustomRole::DEFAULT_PERMISSIONS['agent'] || []
    when 'finance'
      CustomRole::DEFAULT_PERMISSIONS['finance'] || []
    when 'support'
      CustomRole::DEFAULT_PERMISSIONS['support'] || []
    else
      []
    end
  end

  def default_role_color
    {
      'owner' => '#8127E8',
      'administrator' => '#FF6600',
      'finance' => '#10B981',
      'agent' => '#3B82F6',
      'support' => '#8B5CF6'
    }[role] || '#6B7280'
  end

  def push_event_data
    {
      id: id,
      availability: availability,
      role: role,
      user_id: user_id
    }
  end

  private

  def notify_creation
    Rails.configuration.dispatcher.dispatch(AGENT_ADDED, Time.zone.now, account: account)
  end

  def notify_deletion
    Rails.configuration.dispatcher.dispatch(AGENT_REMOVED, Time.zone.now, account: account)
  end

  def update_presence_in_redis
    OnlineStatusTracker.set_status(account.id, user.id, availability)
  end
end

AccountUser.prepend_mod_with('AccountUser')
AccountUser.include_mod_with('Audit::AccountUser')
AccountUser.include_mod_with('Concerns::AccountUser')
