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
  include AssignmentHandler
  include AutoAssignmentHandler
  include ActivityMessageHandler
  include UrlHelper
  include SortHandler
  include PushDataHelper
  include ConversationMuteHelpers
  include WorkingHoursHelper

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  before_validation :validate_additional_attributes
  validates :additional_attributes, jsonb_attributes_length: true
  validates :custom_attributes, jsonb_attributes_length: true
  validates :uuid, uniqueness: true
  validate :validate_referer_url

  enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned, -> { where.not(assignee_id: nil) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }
  scope :unattended, -> { where(first_reply_created_at: nil).or(where.not(waiting_since: nil)) }
  scope :resolvable, lambda { |auto_resolve_duration|
    return none if auto_resolve_duration.to_i.zero?

    open.where('last_activity_at < ? ', Time.now.utc - auto_resolve_duration.days)
  }
  scope :with_intent, lambda { |intent|
    where("additional_attributes->>'intent' = ?", intent)
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
  has_many :conversation_statuses, dependent: :destroy_async
  has_many :conversation_assignments, dependent: :destroy_async
  has_many :attachments, through: :messages

  before_save :ensure_snooze_until_reset
  before_create :determine_conversation_status
  before_create :ensure_waiting_since
  before_create :set_working_hours_attribute

  after_update :assign_contact_to_resolver, if: :saved_change_to_status?
  after_update_commit :execute_after_update_commit_callbacks
  after_create_commit :notify_conversation_creation
  after_create_commit :load_attributes_created_by_db_triggers
  after_create_commit :log_initial_status
  after_commit :log_status_change, if: -> { saved_change_to_status? }

  delegate :auto_resolve_duration, to: :account

  def can_reply?
    channel = inbox&.channel

    return can_reply_on_instagram? if additional_attributes['type'] == 'instagram_direct_message'

    return true unless channel&.messaging_window_enabled?

    messaging_window = inbox.api? ? channel.additional_attributes['agent_reply_time_window'].to_i : 24

    last_message_in_messaging_window?(messaging_window, is_api: inbox.api?)
  end

  def last_activity_at
    self[:last_activity_at] || created_at
  end

  def last_customer_message_at
    # Get last message from customer (incoming message from Contact, not from AgentBot)
    last_customer_msg = messages.where(message_type: :incoming, sender_type: 'Contact').last
    last_customer_msg&.created_at || created_at
  end

  def last_incoming_message
    messages&.incoming&.last
  end

  def last_message_in_messaging_window?(time, is_api: false)
    return false if last_incoming_message.nil?

    last_incoming_message_created_at =
      if is_api && last_incoming_message.content_attributes['external_created_at']
        # external_created_at is stored as epoch timestamp (integer or string), convert to Time
        external_created_at = last_incoming_message.content_attributes['external_created_at']
        Time.at(external_created_at.to_f).utc
      else
        last_incoming_message.created_at
      end

    Time.current < last_incoming_message_created_at + time.hours
  end

  def can_reply_on_instagram?
    global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')

    return false if last_incoming_message.nil?

    if global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']
      Time.current < last_incoming_message.created_at + 7.days
    else
      last_message_in_messaging_window?(24)
    end
  end

  def toggle_status
    # FIXME: implement state machine with aasm
    self.status = open? ? :resolved : :open
    self.status = :open if pending? || snoozed?
    save
  end

  def web_widget?
    inbox.channel_type == 'Channel::WebWidget'
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

  def nudge_created
    additional_attributes['nudge_created'].present? ? Time.zone.parse(additional_attributes['nudge_created']).to_i : created_at.to_i
  end

  def calling_status
    custom_attributes['calling_status']
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

  def notifiable_calling_status_change?
    return false unless saved_change_to_custom_attributes?

    Rails.logger.info('saved_change_to_custom_attributes? true')
    return false if custom_attributes['calling_status'].blank?

    Rails.logger.info('custom_attributes[calling_status].blank? false')
    Rails.logger.info "previous_changes: #{previous_changes.inspect}"
    previous_calling_status = previous_changes['custom_attributes'][0]['calling_status']
    Rails.logger.info "previous_calling_status: #{previous_calling_status}"
    return false if previous_calling_status.present?

    Rails.logger.info('previous_calling_status.blank? true')
    return false if self_assign?(assignee_id)

    Rails.logger.info('self_assign?(assignee_id) false')

    true
  end

  # rubocop:disable Metrics/AbcSize
  def first_call?
    Rails.logger.info('FIRST CALL?')
    return false unless saved_change_to_custom_attributes?

    Rails.logger.info('saved_change_to_custom_attributes? true')
    return false if previous_changes['custom_attributes'].blank?

    Rails.logger.info('previous_changes[custom_attributes].blank? false')
    return false if previous_changes['custom_attributes'][0]['calling_status'].blank?

    Rails.logger.info('previous_changes[custom_attributes][0][calling_status].blank? false')
    return false if previous_changes['custom_attributes'][1]['calling_status'].blank?

    Rails.logger.info('previous_changes[custom_attributes][1][calling_status].blank? false')

    previous_calling_status = previous_changes['custom_attributes'][0]['calling_status']
    current_calling_status = previous_changes['custom_attributes'][1]['calling_status']

    previous_calling_status == 'Scheduled' && current_calling_status != 'Scheduled'
  end

  def call_converted?
    Rails.logger.info('CALL CONVERTED?')
    return false unless saved_change_to_custom_attributes?

    Rails.logger.info('saved_change_to_custom_attributes? true')
    return false if previous_changes['custom_attributes'].blank?

    Rails.logger.info('previous_changes[custom_attributes].blank? false')
    return false if previous_changes['custom_attributes'][0]['calling_status'].blank?

    Rails.logger.info('previous_changes[custom_attributes][0][calling_status].blank? false')
    return false if previous_changes['custom_attributes'][1]['calling_status'].blank?

    Rails.logger.info('previous_changes[custom_attributes][1][calling_status].blank? false')

    previous_calling_status = previous_changes['custom_attributes'][0]['calling_status']
    current_calling_status = previous_changes['custom_attributes'][1]['calling_status']

    current_calling_status == 'Converted' && previous_calling_status != 'Converted'
  end

  def call_dropped?
    Rails.logger.info('CALL DROPPED?')
    return false unless saved_change_to_custom_attributes?

    Rails.logger.info('saved_change_to_custom_attributes? true')
    return false if previous_changes['custom_attributes'].blank?

    Rails.logger.info('previous_changes[custom_attributes].blank? false')
    return false if previous_changes['custom_attributes'][0]['calling_status'].blank?

    Rails.logger.info('previous_changes[custom_attributes][0][calling_status].blank? false')
    return false if previous_changes['custom_attributes'][1]['calling_status'].blank?

    previous_calling_status = previous_changes['custom_attributes'][0]['calling_status']
    current_calling_status = previous_changes['custom_attributes'][1]['calling_status']

    previous_calling_status != 'Dropped' && current_calling_status == 'Dropped'
  end
  # rubocop:enable Metrics/AbcSize

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

  private

  def log_initial_status
    Rails.logger.info("Logging initial status for conversation #{id}")
    ConversationStatus.create!(
      account_id: account_id,
      inbox_id: inbox_id,
      conversation_id: id,
      status: status
    )
  end

  def set_working_hours_attribute
    self.additional_attributes ||= {}
    Rails.logger.info("inbox.channel_type, #{inbox.channel_type}")
    self.additional_attributes['working_hours'] = in_working_hours(account_id, created_at, inbox.channel_type)
  end

  def log_status_change
    Rails.logger.info("Logging status change for conversation #{id}")
    ConversationStatus.create!(
      account_id: account_id,
      inbox_id: inbox_id,
      conversation_id: id,
      status: status
    )
  end

  def execute_after_update_commit_callbacks
    Rails.logger.info('EXECUTING AFTER UPDATE COMMIT CALLBACKS')
    handle_resolved_status_change
    notify_status_change
    create_activity
    notify_conversation_updation
    notify_calling_status_change
  end

  def handle_resolved_status_change
    # When conversation is resolved, clear waiting_since using update_column to avoid callbacks
    return unless saved_change_to_status? && status == 'resolved'

    # rubocop:disable Rails/SkipsModelValidations
    update_column(:waiting_since, nil)
    # rubocop:enable Rails/SkipsModelValidations
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

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Layout/LineLength
  def notify_calling_status_change
    if notifiable_calling_status_change?
      Rails.logger.info('NOTIFYING CALLING STATUS CHANGE')

      Rails.configuration.dispatcher.dispatch(
        'conversation.calling_status_change',
        Time.zone.now,
        conversation: self,
        notifiable_assignee_change: false,
        changed_attributes: previous_changes,
        performed_by: Current.executed_by
      )
    end

    if first_call?
      # can be one of 3 events
      # 1. first_call = if calling_status went from 'Scheduled' to any other value.
      # 2. call_converted = if calling_status went from any other value to 'Converted'.
      # 3. call_dropped = if calling_status went from any other value to 'Dropped'.
      # all cases - Event Start Time = conversation.additional_attributes.nudge_created || conversation.created_at. Event End Time = conversation.updated_at
      Rails.logger.info('DISPATCHING FIRST CALL EVENT')
      Rails.configuration.dispatcher.dispatch('conversation.first_call', Time.zone.now, conversation: self, notifiable_assignee_change: false,
                                                                                        changed_attributes: previous_changes, performed_by: Current.executed_by)
    end

    if call_converted?
      Rails.logger.info('DISPATCHING CALL CONVERTED EVENT')
      Rails.configuration.dispatcher.dispatch('conversation.call_converted', Time.zone.now, conversation: self, notifiable_assignee_change: false,
                                                                                            changed_attributes: previous_changes, performed_by: Current.executed_by)
    end

    return unless call_dropped?

    Rails.logger.info('DISPATCHING CALL DROPPED EVENT')
    Rails.configuration.dispatcher.dispatch('conversation.call_dropped', Time.zone.now, conversation: self, notifiable_assignee_change: false,
                                                                                        changed_attributes: previous_changes, performed_by: Current.executed_by)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Layout/LineLength

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

  def self_assign?(assignee_id)
    assignee_id.present? && Current.user&.id == assignee_id
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

  def assign_contact_to_resolver
    return unless status == 'resolved'
    return unless account.timed_contact_ownership_enabled?
    return if assignee.blank? # Only if conversation has an assignee
    return if assignee_is_bot? # Skip if assignee is Bitespeed bot

    # Assign contact to the agent who resolved the conversation
    contact.assign_ownership!(assignee, Time.current)

    Rails.logger.info "Contact #{contact.id} assigned to agent #{assignee.id} for #{account.contact_ownership_duration_minutes} minutes"
  end

  # Check if the assignee is a Bitespeed bot
  def assignee_is_bot?
    return false if assignee.blank?

    # Check by email pattern (cx.%@bitespeed.co) or name (BiteSpeed Bot)
    assignee.email&.match?(/^cx\..*@bitespeed\.co$/i) || assignee.name == 'BiteSpeed Bot'
  end

  def validate_referer_url
    return unless additional_attributes['referer']

    self['additional_attributes']['referer'] = nil unless url_valid?(additional_attributes['referer'])
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);"
  end
end

Conversation.include_mod_with('Concerns::Conversation')
Conversation.prepend_mod_with('Conversation')
