# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                            :integer          not null, primary key
#  allow_messages_after_resolved :boolean          default(TRUE)
#  auto_assignment_config        :jsonb
#  business_name                 :string
#  channel_type                  :string
#  csat_config                   :jsonb            not null
#  csat_survey_enabled           :boolean          default(FALSE)
#  email_address                 :string
#  enable_auto_assignment        :boolean          default(TRUE)
#  enable_email_collect          :boolean          default(TRUE)
#  greeting_enabled              :boolean          default(FALSE)
#  greeting_message              :string
#  lock_to_single_conversation   :boolean          default(FALSE), not null
#  name                          :string           not null
#  out_of_office_message         :string
#  sender_name_type              :integer          default("friendly"), not null
#  timezone                      :string           default("UTC")
#  working_hours_enabled         :boolean          default(FALSE)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :integer          not null
#  channel_id                    :integer          not null
#  portal_id                     :bigint
#
# Indexes
#
#  index_inboxes_on_account_id                   (account_id)
#  index_inboxes_on_channel_id_and_channel_type  (channel_id,channel_type)
#  index_inboxes_on_portal_id                    (portal_id)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => portals.id)
#

class Inbox < ApplicationRecord
  include Reportable
  include Avatarable
  include OutOfOffisable
  include AccountCacheRevalidator
  include AssignmentV2FeatureFlag
  include InboxAgentAvailability
  include InboxChannelTypes
  include InboxWebhooks
  include InboxNameSanitization

  # Not allowing characters:
  validates :name, presence: true
  validates :account_id, presence: true
  validates :timezone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  validates :out_of_office_message, length: { maximum: Limits::OUT_OF_OFFICE_MESSAGE_MAX_LENGTH }
  validates :greeting_message, length: { maximum: Limits::GREETING_MESSAGE_MAX_LENGTH }
  validate :ensure_valid_max_assignment_limit

  belongs_to :account
  belongs_to :portal, optional: true

  belongs_to :channel, polymorphic: true, dependent: :destroy

  has_many :campaigns, dependent: :destroy_async
  has_many :contact_inboxes, dependent: :destroy_async
  has_many :contacts, through: :contact_inboxes

  has_many :inbox_members, dependent: :destroy_async
  has_many :members, through: :inbox_members, source: :user
  has_many :conversations, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async

  has_one :agent_bot_inbox, dependent: :destroy_async
  has_one :agent_bot, through: :agent_bot_inbox
  has_many :webhooks, dependent: :destroy_async
  has_many :hooks, dependent: :destroy_async, class_name: 'Integrations::Hook'

  # Assignment V2 associations
  has_one :inbox_assignment_policy, dependent: :destroy
  has_one :assignment_policy, through: :inbox_assignment_policy

  enum sender_name_type: { friendly: 0, professional: 1 }

  after_destroy :delete_round_robin_agents

  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event

  scope :order_by_name, -> { order('lower(name) ASC') }

  # Adds multiple members to the inbox
  # @param user_ids [Array<Integer>] Array of user IDs to add as members
  # @return [void]
  def add_members(user_ids)
    inbox_members.create!(user_ids.map { |user_id| { user_id: user_id } })
    update_account_cache
  end

  # Removes multiple members from the inbox
  # @param user_ids [Array<Integer>] Array of user IDs to remove
  # @return [void]
  def remove_members(user_ids)
    inbox_members.where(user_id: user_ids).destroy_all
    update_account_cache
  end

  def assignable_agents
    (account.users.where(id: members.select(:user_id)) + account.administrators).uniq
  end

  # Assignment V2 methods
  def assignment_v2_enabled?
    account.assignment_v2_enabled? && assignment_policy.present? && assignment_policy.enabled?
  end

  def auto_assignment_enabled?
    if assignment_v2_enabled?
      assignment_policy.present? && assignment_policy.enabled?
    else
      enable_auto_assignment?
    end
  end

  # Returns inbox members who are available for assignment
  # This method performs all filtering upfront at the database level for optimal performance
  #
  # Filters applied:
  # 1. Online status - Only agents marked as 'online' in OnlineStatusTracker
  # 2. Capacity limits (Enterprise) - Agents who haven't reached their conversation limit
  # 3. Rate limiting - Agents who haven't exceeded rate limits (when implemented)
  # 4. User exclusions - Specific users can be excluded (e.g., for reassignment)
  #
  # @param options [Hash] Additional filter options
  # @option options [Boolean] :check_capacity (true) Whether to check capacity limits
  # @option options [Boolean] :check_rate_limits (false) Whether to check rate limits
  # @option options [Array<Integer>] :exclude_user_ids Users to exclude from results
  #
  # @return [ActiveRecord::Relation<InboxMember>] Available inbox members with preloaded users
  #
  # @example Get all available agents
  #   inbox.available_agents
  #
  # @example Get available agents excluding specific users
  #   inbox.available_agents(exclude_user_ids: [1, 2, 3])
  #
  # @example Get available agents without capacity check (faster but less accurate)
  #   inbox.available_agents(check_capacity: false)
  def available_agents(options = {})
    options = { check_capacity: true }.merge(options)

    # Get online agent IDs
    online_agent_ids = fetch_online_agent_ids
    return inbox_members.none if online_agent_ids.empty?

    # Base query - only online agents
    scope = build_online_agents_scope(online_agent_ids)

    # Apply filters
    apply_agent_filters(scope, options)
  end

  private

  def build_online_agents_scope(online_agent_ids)
    inbox_members
      .joins(:user)
      .where(users: { id: online_agent_ids })
      .includes(:user)
  end

  def apply_agent_filters(scope, options)
    # Exclude specific users if requested
    scope = scope.where.not(users: { id: options[:exclude_user_ids] }) if options[:exclude_user_ids].present?

    # Apply capacity filtering for enterprise accounts
    scope = filter_by_capacity(scope) if options[:check_capacity] && enterprise_capacity_enabled?

    # Apply rate limiting if implemented
    scope = filter_by_rate_limits(scope) if options[:check_rate_limits] && defined?(AssignmentV2::RateLimiter)

    # Exclude agents who are on leave
    scope = filter_agents_on_leave(scope) if options[:exclude_on_leave] != false

    scope
  end

  def fetch_online_agent_ids
    OnlineStatusTracker.get_available_users(account_id)
                       .select { |_key, value| value.eql?('online') }
                       .keys
                       .map(&:to_i)
  end

  def enterprise_capacity_enabled?
    defined?(Enterprise) &&
      account.custom_attributes&.dig('enterprise_features', 'capacity_management').present?
  end

  def filter_by_capacity(inbox_members_scope)
    return inbox_members_scope unless capacity_check_required?

    assignment_counts = fetch_assignment_counts

    inbox_members_scope.select do |inbox_member|
      agent_has_capacity?(inbox_member, assignment_counts)
    end
  end

  def capacity_check_required?
    defined?(Enterprise::InboxCapacityLimit) &&
      account.account_users.joins(:agent_capacity_policy).exists?
  end

  def fetch_assignment_counts
    conversations
      .where(status: :open)
      .where.not(assignee_id: nil)
      .group(:assignee_id)
      .count
  end

  def agent_has_capacity?(inbox_member, assignment_counts)
    user = inbox_member.user
    account_user = account.account_users.find_by(user: user)

    return true unless account_user&.agent_capacity_policy_id

    capacity_limit = fetch_capacity_limit(account_user.agent_capacity_policy_id)
    return true unless capacity_limit&.conversation_limit

    current_count = assignment_counts[user.id] || 0
    current_count < capacity_limit.conversation_limit
  end

  def fetch_capacity_limit(policy_id)
    Enterprise::InboxCapacityLimit
      .where(agent_capacity_policy_id: policy_id)
      .find_by(inbox_id: id)
  end

  def filter_by_rate_limits(inbox_members_scope)
    # Filter out agents who have exceeded rate limits
    return inbox_members_scope unless assignment_policy&.enabled?

    # Get IDs of inbox members within rate limits
    valid_inbox_member_ids = inbox_members_scope.find_each.filter_map do |inbox_member|
      rate_limiter = AssignmentV2::RateLimiter.new(inbox: self, user: inbox_member.user)
      inbox_member.id if rate_limiter.within_limits?
    end

    # Return filtered scope maintaining ActiveRecord relation
    inbox_members_scope.where(id: valid_inbox_member_ids)
  end

  def filter_agents_on_leave(inbox_members_scope)
    # Get users on active leave
    user_ids_on_leave = account.leaves
                               .where(status: :approved)
                               .where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
                               .pluck(:user_id)

    return inbox_members_scope if user_ids_on_leave.empty?

    # Exclude inbox members whose users are on leave
    inbox_members_scope.where.not(user_id: user_ids_on_leave)
  end

  def dispatch_create_event
    return if ENV['ENABLE_INBOX_EVENTS'].blank?

    Rails.configuration.dispatcher.dispatch(INBOX_CREATED, Time.zone.now, inbox: self)
  end

  def dispatch_update_event
    return if ENV['ENABLE_INBOX_EVENTS'].blank?

    Rails.configuration.dispatcher.dispatch(INBOX_UPDATED, Time.zone.now, inbox: self, changed_attributes: previous_changes)
  end

  def ensure_valid_max_assignment_limit
    # overridden in enterprise/app/models/enterprise/inbox.rb
  end

  def delete_round_robin_agents
    ::AutoAssignment::InboxRoundRobinService.new(inbox: self).clear_queue
  end

  def check_channel_type?
    ['Channel::Email', 'Channel::Api', 'Channel::WebWidget'].include?(channel_type)
  end
end

Inbox.prepend_mod_with('Inbox')
Inbox.include_mod_with('Audit::Inbox')
Inbox.include_mod_with('Concerns::Inbox')
