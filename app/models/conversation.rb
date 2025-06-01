# == Schema Information
#
# Table name: conversations
#
#  id                     :integer          not null, primary key
#  additional_attributes  :jsonb
#  agent_last_seen_at     :datetime
#  assignee_last_seen_at  :datetime
#  cached_label_list      :text
#  contact_last_seen_at   :datetime
#  custom_attributes      :jsonb
#  first_reply_created_at :datetime
#  identifier             :string
#  last_activity_at       :datetime         not null
#  priority               :integer
#  snoozed_until          :datetime
#  status                 :integer          default("open"), not null
#  uuid                   :uuid             not null
#  waiting_since          :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  assignee_id            :integer
#  campaign_id            :bigint
#  contact_id             :bigint
#  contact_inbox_id       :bigint
#  display_id             :integer          not null
#  inbox_id               :integer          not null
#  sla_policy_id          :bigint
#  team_id                :bigint
#
# Indexes
#
#  conv_acid_inbid_stat_asgnid_idx                    (account_id,inbox_id,status,assignee_id)
#  index_conversations_on_account_id                  (account_id)
#  index_conversations_on_account_id_and_display_id   (account_id,display_id) UNIQUE
#  index_conversations_on_assignee_id_and_account_id  (assignee_id,account_id)
#  index_conversations_on_campaign_id                 (campaign_id)
#  index_conversations_on_contact_id                  (contact_id)
#  index_conversations_on_contact_inbox_id            (contact_inbox_id)
#  index_conversations_on_first_reply_created_at      (first_reply_created_at)
#  index_conversations_on_id_and_account_id           (account_id,id)
#  index_conversations_on_inbox_id                    (inbox_id)
#  index_conversations_on_priority                    (priority)
#  index_conversations_on_status_and_account_id       (status,account_id)
#  index_conversations_on_status_and_priority         (status,priority)
#  index_conversations_on_team_id                     (team_id)
#  index_conversations_on_uuid                        (uuid) UNIQUE
#  index_conversations_on_waiting_since               (waiting_since)
#

class Conversation < ApplicationRecord
  include Labelable
  include LlmFormattable
  include AssignmentHandler
  include AutoAssignmentHandler
  include ActivityMessageHandler
  include UrlHelper
  include SortHandler
  include PushDataHelper
  include ConversationMuteHelpers
  include Events::Types
  include ConversationHelpers
  include RoundRobinHandler
  include NotificationSubscriptionHandler

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  validates_with JsonbAttributesLengthValidator
  before_validation :validate_additional_attributes
  validates :additional_attributes, jsonb_attributes_length: true
  validates :custom_attributes, jsonb_attributes_length: true
  validates :uuid, uniqueness: true
  validate :validate_referer_url

  enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }
  enum priority: { nil => nil, urgent: 1, high: 2, medium: 3, low: 4 }

  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned, -> { where.not(assignee_id: nil) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }
  scope :unattended, -> { where(first_reply_created_at: nil).or(where.not(waiting_since: nil)) }
  scope :resolvable_not_waiting, lambda { |auto_resolve_after|
    return none if auto_resolve_after.to_i.zero?

    open.where('last_activity_at < ? AND waiting_since IS NULL', Time.now.utc - auto_resolve_after.minutes)
  }
  scope :resolvable_all, lambda { |auto_resolve_after|
    return none if auto_resolve_after.to_i.zero?

    open.where('last_activity_at < ?', Time.now.utc - auto_resolve_after.minutes)
  }

  scope :last_user_message_at, lambda {
    joins(
      "INNER JOIN (#{last_messaged_conversations.to_sql}) AS grouped_conversations
      ON grouped_conversations.conversation_id = conversations.id"
    ).sort_on_last_user_message_at
  }

  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User', optional: true, inverse_of: :assigned_conversations
  belongs_to :contact
  belongs_to :contact_inbox
  belongs_to :team, optional: true
  belongs_to :campaign, optional: true

  has_many :mentions, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async, autosave: true
  has_one :csat_survey_response, dependent: :destroy_async
  has_many :conversation_participants, dependent: :destroy_async
  has_many :notifications, as: :primary_actor, dependent: :destroy_async
  has_many :attachments, through: :messages
  has_many :reporting_events, dependent: :destroy_async
  has_many :labels, through: :conversation_labels, source: :label
  has_many :conversation_labels, dependent: :destroy
  has_many :notes, dependent: :destroy

  before_save :ensure_snooze_until_reset
  before_create :determine_conversation_status
  before_create :ensure_waiting_since
  before_create :set_bot_conversation
  before_save :set_priority_from_additional_attributes

  after_update_commit :execute_after_update_commit_callbacks
  after_create_commit :notify_conversation_creation
  after_create_commit :load_attributes_created_by_db_triggers
  after_update_commit :auto_update_interaction_patterns, if: :should_update_interaction_patterns?
  after_update_commit :run_after_update_commit_callbacks

  delegate :auto_resolve_after, to: :account

  store :additional_attributes, accessors: [:browser_language, :referer, :initiated_at, :custom_attributes], coder: JSON
  store :content_attributes, accessors: [:conversation_context, :interaction_patterns, :resolution_context, :customer_satisfaction], coder: JSON

  def can_reply?
    Conversations::MessageWindowService.new(self).can_reply?
  end

  def language
    additional_attributes&.dig('conversation_language')
  end

  # Be aware: The precision of created_at and last_activity_at may differ from Ruby's Time precision.
  # Our DB column (see schema) stores timestamps with second-level precision (no microseconds), so
  # if you assign a Ruby Time with microseconds, the DB will truncate it. This may cause subtle differences
  # if you compare or copy these values in Ruby, also in our specs
  # So in specs rely on to be_with(1.second) instead of to eq()
  # TODO: Migrate to use a timestamp with microsecond precision
  def last_activity_at
    self[:last_activity_at] || created_at
  end

  def last_incoming_message
    messages&.incoming&.last
  end

  def toggle_status
    # FIXME: implement state machine with aasm
    self.status = open? ? :resolved : :open
    self.status = :open if pending? || snoozed?
    save
  end

  def toggle_priority(priority = nil)
    self.priority = priority.presence
    save
  end

  def bot_handoff!
    open!
    dispatcher_dispatch(CONVERSATION_BOT_HANDOFF)
  end

  def unread_messages
    agent_last_seen_at.present? ? messages.created_since(agent_last_seen_at) : messages
  end

  def unread_incoming_messages
    unread_messages.where(account_id: account_id).incoming.last(10)
  end

  def cached_label_list_array
    (cached_label_list || '').split(',').map(&:strip)
  end

  def notifiable_assignee_change?
    return false unless saved_change_to_assignee_id?
    return false if assignee_id.blank?
    return false if self_assign?(assignee_id)

    true
  end

  def tweet?
    inbox.inbox_type == 'Twitter' && additional_attributes['type'] == 'tweet'
  end

  def recent_messages
    messages.chat.last(5)
  end

  def csat_survey_link
    "#{ENV.fetch('FRONTEND_URL', nil)}/survey/responses/#{uuid}"
  end

  def dispatch_conversation_updated_event(previous_changes = nil)
    dispatcher_dispatch(CONVERSATION_UPDATED, previous_changes)
  end

  def auto_update_interaction_patterns
    update_interaction_patterns
    save! if changed?
  end

  def should_update_interaction_patterns?
    saved_change_to_status? || saved_change_to_assignee_id? || saved_change_to_priority?
  end

  def update_interaction_patterns
    patterns = {
      messages_count: messages.count,
      agent_response_time: calculate_avg_agent_response_time,
      customer_response_time: calculate_avg_customer_response_time,
      handoff_count: calculate_handoff_count,
      last_activity_type: determine_last_activity_type
    }
    
    set_content_attribute('interaction_patterns', patterns)
  end

  def calculate_avg_agent_response_time
    agent_messages = messages.outgoing.joins(:sender).where(users: { account_users: { role: ['agent', 'administrator'] } })
    return 0 if agent_messages.empty?

    total_time = 0
    count = 0

    agent_messages.each do |message|
      previous_customer_message = messages.incoming.where('created_at < ?', message.created_at).last
      if previous_customer_message
        response_time = message.created_at - previous_customer_message.created_at
        total_time += response_time
        count += 1
      end
    end

    count > 0 ? (total_time / count).round(2) : 0
  end

  def calculate_avg_customer_response_time
    customer_messages = messages.incoming
    return 0 if customer_messages.empty?

    total_time = 0
    count = 0

    customer_messages.each do |message|
      previous_agent_message = messages.outgoing.where('created_at < ?', message.created_at).last
      if previous_agent_message
        response_time = message.created_at - previous_agent_message.created_at
        total_time += response_time
        count += 1
      end
    end

    count > 0 ? (total_time / count).round(2) : 0
  end

  def calculate_handoff_count
    # Count how many times the conversation was reassigned
    return 0 unless respond_to?(:audits)
    
    audits.where(auditable_type: 'Conversation', action: 'update')
          .where("audited_changes ? 'assignee_id'")
          .count
  rescue
    0
  end

  def determine_last_activity_type
    last_message = messages.last
    return nil unless last_message

    case last_message.message_type
    when 'incoming'
      'customer_message'
    when 'outgoing'
      'agent_message'
    else
      'system_activity'
    end
  end

  def set_content_attribute(key, value)
    self.content_attributes = {} if content_attributes.nil?
    self.content_attributes = content_attributes.merge(key => value)
  end

  def get_content_attribute(key)
    content_attributes&.dig(key)
  end

  def track_conversation_context(context_data)
    set_content_attribute('conversation_context', context_data)
  end

  def set_resolution_context(resolution_data)
    set_content_attribute('resolution_context', resolution_data)
  end

  def set_customer_satisfaction(satisfaction_data)
    set_content_attribute('customer_satisfaction', satisfaction_data)
  end

  private

  def execute_after_update_commit_callbacks
    notify_status_change
    create_activity
    notify_conversation_updation
  end

  def ensure_snooze_until_reset
    self.snoozed_until = nil unless snoozed?
  end

  def ensure_waiting_since
    self.waiting_since = created_at
  end

  def validate_additional_attributes
    self.additional_attributes = {} unless additional_attributes.is_a?(Hash)
  end

  def determine_conversation_status
    self.status = :resolved and return if contact.blocked?

    # Message template hooks aren't executed for conversations from campaigns
    # So making these conversations open for agent visibility
    return if campaign.present?

    # TODO: make this an inbox config instead of assuming bot conversations should start as pending
    self.status = :pending if inbox.active_bot?
  end

  def notify_conversation_creation
    dispatcher_dispatch(CONVERSATION_CREATED)
  end

  def notify_conversation_updation
    return unless previous_changes.keys.present? && allowed_keys?

    dispatch_conversation_updated_event(previous_changes)
  end

  def list_of_keys
    %w[team_id assignee_id status snoozed_until custom_attributes label_list waiting_since first_reply_created_at
       priority]
  end

  def allowed_keys?
    (
      previous_changes.keys.intersect?(list_of_keys) ||
      (previous_changes['additional_attributes'].present? && previous_changes['additional_attributes'][1].keys.intersect?(%w[conversation_language]))
    )
  end

  def load_attributes_created_by_db_triggers
    # Display id is set via a trigger in the database
    # So we need to specifically fetch it after the record is created
    # We can't use reload because it will clear the previous changes, which we need for the dispatcher
    obj_from_db = self.class.find(id)
    self[:display_id] = obj_from_db[:display_id]
    self[:uuid] = obj_from_db[:uuid]
  end

  def notify_status_change
    {
      CONVERSATION_OPENED => -> { saved_change_to_status? && open? },
      CONVERSATION_RESOLVED => -> { saved_change_to_status? && resolved? },
      CONVERSATION_STATUS_CHANGED => -> { saved_change_to_status? },
      CONVERSATION_READ => -> { saved_change_to_contact_last_seen_at? },
      CONVERSATION_CONTACT_CHANGED => -> { saved_change_to_contact_id? }
    }.each do |event, condition|
      condition.call && dispatcher_dispatch(event, status_change)
    end
  end

  def dispatcher_dispatch(event_name, changed_attributes = nil)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, conversation: self, notifiable_assignee_change: notifiable_assignee_change?,
                                                                       changed_attributes: changed_attributes,
                                                                       performed_by: Current.executed_by)
  end

  def conversation_status_changed_to_open?
    return false unless open?
    # saved_change_to_status? method only works in case of update
    return true if previous_changes.key?(:id) || saved_change_to_status?
  end

  def create_label_change(user_name)
    return unless user_name

    previous_labels, current_labels = previous_changes[:label_list]
    return unless (previous_labels.is_a? Array) && (current_labels.is_a? Array)

    dispatcher_dispatch(CONVERSATION_UPDATED, previous_changes)

    create_label_added(user_name, current_labels - previous_labels)
    create_label_removed(user_name, previous_labels - current_labels)
  end

  def validate_referer_url
    return unless additional_attributes['referer']

    self['additional_attributes']['referer'] = nil unless url_valid?(additional_attributes['referer'])
  end

  def set_bot_conversation
    self.status = :pending if inbox.active_bot?
  end

  def set_priority_from_additional_attributes
    self.priority = additional_attributes['priority'].presence
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);"
  end
end

Conversation.include_mod_with('Concerns::Conversation')
Conversation.prepend_mod_with('Conversation')
