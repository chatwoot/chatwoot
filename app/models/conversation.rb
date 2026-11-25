# == Schema Information
#
# Table name: conversations
#
#  id                         :integer          not null, primary key
#  additional_attributes      :jsonb
#  agent_last_seen_at         :datetime
#  ai_assignee_type           :string
#  assignee_last_seen_at      :datetime
#  cached_label_list          :text
#  contact_last_seen_at       :datetime
#  custom_attributes          :jsonb
#  first_reply_created_at     :datetime
#  group_type                 :integer          default("individual"), not null
#  identifier                 :string
#  last_activity_at           :datetime         not null
#  priority                   :integer
#  snoozed_until              :datetime
#  status                     :integer          default("open"), not null
#  status_changed_at          :datetime
#  uuid                       :uuid             not null
#  waiting_since              :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :integer          not null
#  assignee_agent_bot_id      :bigint
#  assignee_id                :integer
#  campaign_id                :bigint
#  contact_id                 :bigint           not null
#  contact_inbox_id           :bigint
#  display_id                 :integer          not null
#  inbox_id                   :integer          not null
#  redirect_origin_display_id :integer
#  sla_policy_id              :bigint
#  team_id                    :bigint
#
# Indexes
#
#  conv_acid_inbid_stat_asgnid_idx                      (account_id,inbox_id,status,assignee_id)
#  index_conversations_on_account_id                    (account_id)
#  index_conversations_on_account_id_and_display_id     (account_id,display_id) UNIQUE
#  index_conversations_on_account_id_and_group_type     (account_id,group_type)
#  index_conversations_on_account_id_status_created_at  (account_id,status,created_at)
#  index_conversations_on_assignee_id_and_account_id    (assignee_id,account_id)
#  index_conversations_on_campaign_id                   (campaign_id)
#  index_conversations_on_contact_id                    (contact_id)
#  index_conversations_on_contact_inbox_id              (contact_inbox_id)
#  index_conversations_on_created_at                    (created_at)
#  index_conversations_on_first_reply_created_at        (first_reply_created_at)
#  index_conversations_on_id_and_account_id             (account_id,id)
#  index_conversations_on_identifier_and_account_id     (identifier,account_id)
#  index_conversations_on_inbox_id                      (inbox_id)
#  index_conversations_on_inbox_id_and_group_type       (inbox_id,group_type)
#  index_conversations_on_priority                      (priority)
#  index_conversations_on_sla_policy_id                 (sla_policy_id) WHERE (sla_policy_id IS NOT NULL)
#  index_conversations_on_status_and_account_id         (status,account_id)
#  index_conversations_on_status_and_priority           (status,priority)
#  index_conversations_on_team_id                       (team_id)
#  index_conversations_on_uuid                          (uuid) UNIQUE
#  index_conversations_on_waiting_since                 (waiting_since)
#

class Conversation < ApplicationRecord
  include JsonColumnMerge
  include Labelable
  include LlmFormattable
  include ReopenTeamAssigneeHandler
  include ReopenAgentBotHandler
  include AssignmentHandler
  include AutoAssignmentHandler
  include ActivityMessageHandler
  include UrlHelper
  include SortHandler
  include PushDataHelper
  include ConversationMuteHelpers

  CONVERSATION_UPDATED_ADDITIONAL_ATTRIBUTE_KEYS = %w[conversation_language auto_translate_disabled].freeze
  FILTERED_UNREAD_COUNT_ADDITIONAL_ATTRIBUTE_KEYS = %w[browser_language conversation_language mail_subject referer].freeze
  FILTERED_UNREAD_COUNT_UPDATE_KEYS = %w[
    cached_label_list campaign_id custom_attributes first_reply_created_at label_list last_activity_at priority snoozed_until waiting_since
  ].freeze
  private_constant :CONVERSATION_UPDATED_ADDITIONAL_ATTRIBUTE_KEYS, :FILTERED_UNREAD_COUNT_ADDITIONAL_ATTRIBUTE_KEYS,
                   :FILTERED_UNREAD_COUNT_UPDATE_KEYS

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  before_validation :validate_additional_attributes
  before_validation :clear_invalid_ai_assignee
  validates :additional_attributes, jsonb_attributes_length: true
  validates :custom_attributes, jsonb_attributes_length: true
  validates :uuid, uniqueness: true
  validate :validate_referer_url

  enum :status, { open: 0, resolved: 1, pending: 2, snoozed: 3 }
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }
  enum :group_type, { individual: 0, group: 1 }, prefix: true

  scope :unassigned, -> { where(assignee_id: nil, assignee_agent_bot_id: nil) }
  scope :assigned, -> { where.not(assignee_id: nil).or(where.not(assignee_agent_bot_id: nil)) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }
  scope :sort_on_unread, lambda { |_direction|
    order(unread_messages_count_arel.desc).sort_on_last_activity_at('desc')
  }
  scope :unattended, -> { where(first_reply_created_at: nil).or(where.not(waiting_since: nil)) }
  scope :resolvable_not_waiting, lambda { |auto_resolve_after|
    return none if auto_resolve_after.to_i.zero?

    open.where('last_activity_at < ? AND waiting_since IS NULL', Time.now.utc - auto_resolve_after.minutes)
  }
  scope :resolvable_all, lambda { |auto_resolve_after|
    return none if auto_resolve_after.to_i.zero?

    open.where('last_activity_at < ?', Time.now.utc - auto_resolve_after.minutes)
  }

  # Puts the conversations the given user pinned first, most recently pinned on top. The join is kept as a
  # literal SQL string (with the table name spelled out in the ON clause) so Rails does not promote it to an
  # eager load, and the unique index on [user_id, conversation_id] keeps it 1:0..1, so no row is duplicated.
  scope :pinned_first_for, lambda { |user|
    joins(
      sanitize_sql_array(
        ['LEFT OUTER JOIN conversation_pins ON conversation_pins.conversation_id = conversations.id AND conversation_pins.user_id = ?',
         user.id]
      )
    ).order(Arel.sql('conversation_pins.created_at DESC NULLS LAST'))
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
  belongs_to :ai_assignee,
             polymorphic: true,
             foreign_key: :assignee_agent_bot_id,
             foreign_type: :ai_assignee_type,
             optional: true
  belongs_to :contact
  belongs_to :contact_inbox
  belongs_to :team, optional: true
  belongs_to :campaign, optional: true

  has_many :mentions, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async, autosave: true
  has_one :csat_survey_response, dependent: :destroy_async
  has_many :conversation_participants, dependent: :destroy_async
  has_many :conversation_pins, dependent: :destroy_async
  has_many :notifications, as: :primary_actor, dependent: :destroy_async
  has_many :attachments, through: :messages
  has_many :reporting_events, dependent: :destroy_async
  has_many :scheduled_messages, dependent: :destroy
  has_many :recurring_scheduled_messages, dependent: :destroy
  has_many :automation_rule_pending_executions, dependent: :delete_all

  before_save :ensure_snooze_until_reset
  before_save :set_status_changed_at
  before_create :determine_conversation_status
  before_create :ensure_waiting_since
  after_create :mark_contact_as_lead

  after_update_commit :execute_after_update_commit_callbacks
  after_create_commit :notify_conversation_creation
  after_create_commit :load_attributes_created_by_db_triggers
  before_destroy :set_unread_count_deletion_data
  after_destroy_commit :notify_conversation_deletion

  delegate :auto_resolve_after, to: :account

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
    messages.where(account_id: account_id)&.incoming&.last
  end

  # Seeds `currentChat.messages` in the dashboard AND doubles as the `before`
  # cursor in setActiveChat → fetchPreviousMessages, where MessageFinder pages
  # with `id < before`. It must therefore be the newest message the dashboard
  # renders. Filtering by `message_type` or `private` here silently hides every
  # message created after the one we pick — that is how activity messages
  # ("Conversation was marked resolved by ...") vanished from the history.
  # Chat list previews use `last_non_activity_message`: keep the two separate.
  # Agent-facing payloads only — the cable broadcast reaches the contact too and
  # keeps its own narrower query (see EventDataPresenter#push_messages).
  # The `id` tie-break is load-bearing: pagination compares ids, so on a
  # `created_at` tie the cursor has to be the highest id or the rows between
  # them fall through the same crack. Imports write second-precision
  # timestamps in bulk (DataImports::Intercom::Importer), so ties are real.
  def dashboard_seed_message
    messages.where(account_id: account_id)
            .hide_removed_reactions
            .includes([{ attachments: [{ file_attachment: [:blob] }] }])
            .reorder(created_at: :desc, id: :desc)
            .first
  end

  # Drives the chat list preview, which must never read "Conversation was
  # marked resolved by ...". Unlike `dashboard_seed_message`, skipping activity
  # messages here is intentional.
  def last_non_activity_message
    messages.where(account_id: account_id)
            .non_activity_messages
            .hide_removed_reactions
            .includes([{ attachments: [{ file_attachment: [:blob] }] }])
            .reorder(created_at: :desc, id: :desc)
            .first
  end

  def toggle_status
    # FIXME: implement state machine with aasm
    self.status = toggled_status
    save # rubocop:disable Rails/SaveBang
  end

  # The status a toggle lands on, without writing it. Callers that have another
  # change to make in the same save need this: `previous_changes` only carries
  # the last save, and every status callback reads `saved_change_to_status?`
  # from it.
  def toggled_status
    return :open if pending? || snoozed?

    open? ? :resolved : :open
  end

  def toggle_priority(priority = nil)
    self.priority = priority.presence
    save!
  end

  def bot_handoff!(dispatch_event: true)
    # Best-effort eligibility check, not a lock against concurrent takeovers.
    # The dashboard checks assignment/status again before playing the alert.
    return false unless pending?

    update!(waiting_since: Time.current) if waiting_since.blank?
    self.ai_assignee = nil
    open!
    dispatch_bot_handoff_event if dispatch_event
  end

  def dispatch_bot_handoff_event
    dispatcher_dispatch(CONVERSATION_BOT_HANDOFF)
  end

  def unread_messages
    agent_last_seen_at.present? ? messages.created_since(agent_last_seen_at) : messages
  end

  def assignee_unread_messages
    assignee_last_seen_at.present? ? messages.created_since(assignee_last_seen_at) : messages
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

  # Virtual attribute till we switch completely to polymorphic assignee
  def assignee_type
    # Only for an assignee that resolves: a type naming a class this install does not have
    # (an assistant, without enterprise/) assigns nothing.
    return ai_assignee_type if ai_assignee_type.present? && ai_assignee.present?
    return 'User' if assignee_id.present?

    nil
  end

  def assigned_entity
    ai_assignee || assignee
  end

  def tweet?
    inbox.inbox_type == 'Twitter' && additional_attributes['type'] == 'tweet'
  end

  def self.unread_messages_count_arel
    messages = Message.arel_table
    conversations = arel_table
    unread_messages = messages
                      .project(messages[:id].count)
                      .where(unread_messages_condition(messages, conversations))

    Arel::Nodes::Grouping.new(unread_messages.ast)
  end

  def self.unread_messages_condition(messages, conversations)
    messages[:conversation_id].eq(conversations[:id])
                              .and(messages[:account_id].eq(conversations[:account_id]))
                              .and(messages[:message_type].eq(Message.message_types[:incoming]))
                              .and(
                                conversations[:agent_last_seen_at].eq(nil)
                                  .or(messages[:created_at].gt(conversations[:agent_last_seen_at]))
                              )
  end

  def recent_messages
    messages.chat.last(5)
  end

  def csat_survey_link
    "#{ENV.fetch('FRONTEND_URL', nil)}/survey/responses/#{uuid}"
  end

  def dispatch_conversation_updated_event(previous_changes = nil, broadcast_metadata: nil)
    dispatcher_dispatch(CONVERSATION_UPDATED, previous_changes, broadcast_metadata: broadcast_metadata)
  end

  private

  def execute_after_update_commit_callbacks
    handle_resolved_status_change
    unpin_for_everyone_on_resolve
    notify_status_change
    create_activity
    invalidate_filtered_unread_count_conversation
    notify_conversation_updation
  end

  def handle_resolved_status_change
    # When conversation is resolved, clear waiting_since using update_column to avoid callbacks
    return unless saved_change_to_status? && status == 'resolved'

    # rubocop:disable Rails/SkipsModelValidations
    update_column(:waiting_since, nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # A resolved conversation leaves the agent's open list, so it should not keep occupying one of their pin slots.
  def unpin_for_everyone_on_resolve
    return unless saved_change_to_status? && resolved?

    conversation_pins.destroy_all
  end

  def ensure_snooze_until_reset
    self.snoozed_until = nil unless snoozed?
  end

  def set_status_changed_at
    self.status_changed_at = Time.current if new_record? || status_changed?
  end

  def ensure_waiting_since
    self.waiting_since = created_at
  end

  def mark_contact_as_lead
    # Non-bang on purpose: a contact that no longer passes its own validations must not stop the conversation.
    contact.update(contact_type: :lead) if contact.visitor? # rubocop:disable Rails/SaveBang
  end

  def validate_additional_attributes
    self.additional_attributes = {} unless additional_attributes.is_a?(Hash)
  end

  def clear_invalid_ai_assignee
    self.ai_assignee = nil if assignee_id.present? || (status_changed? && open?)
  end

  def determine_conversation_status
    self.status = :resolved and return if contact.blocked?

    return handle_campaign_status if campaign.present?

    set_active_bot_conversation if inbox.active_bot?
  end

  def handle_campaign_status
    set_active_bot_conversation if campaign.sender_id.nil? && inbox.active_bot?
  end

  def set_active_bot_conversation
    # TODO: make this an inbox config instead of assuming bot conversations should start as pending
    self.status = :pending
    return unless inbox.agent_bot_inbox&.active? && assignee_id.blank?

    self.ai_assignee = inbox.agent_bot
  end

  def notify_conversation_creation
    dispatcher_dispatch(CONVERSATION_CREATED)
  end

  def notify_conversation_deletion
    return if @unread_count_deletion_data.blank?

    Rails.configuration.dispatcher.dispatch(CONVERSATION_DELETED, Time.zone.now, conversation_data: @unread_count_deletion_data)
  end

  def notify_conversation_updation
    return unless previous_changes.keys.present? && allowed_keys?

    dispatch_conversation_updated_event(previous_changes)
  end

  # Every key here answers the same question: does a consumer of this conversation need to be TOLD
  # when it changes? `redirect_origin_display_id` does, and only this list can say so. The pairing is
  # written on an existing conversation whenever a message-less redirect token resumes one, and that
  # write carries no message and creates nothing, so without an event of its own the change is
  # invisible and the consumer keeps acting on the previous episode's origin (fazer-ai/agents#222).
  def list_of_keys
    %w[team_id assignee_id assignee_agent_bot_id ai_assignee_type status snoozed_until custom_attributes label_list waiting_since
       first_reply_created_at priority redirect_origin_display_id]
  end

  def allowed_keys?
    previous_changes.keys.intersect?(list_of_keys) ||
      additional_attributes_changed?(CONVERSATION_UPDATED_ADDITIONAL_ATTRIBUTE_KEYS)
  end

  def invalidate_filtered_unread_count_conversation
    return unless filtered_unread_count_update?

    ::Conversations::UnreadCounts::FilteredCountInvalidator.new(account).conversation_changed!
  end

  def filtered_unread_count_update?
    previous_changes.keys.intersect?(FILTERED_UNREAD_COUNT_UPDATE_KEYS) ||
      additional_attributes_changed?(FILTERED_UNREAD_COUNT_ADDITIONAL_ATTRIBUTE_KEYS)
  end

  def additional_attributes_changed?(keys)
    Array(previous_changes['additional_attributes']).compact.any? { |attributes| attributes.keys.intersect?(keys) }
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

  def dispatcher_dispatch(event_name, changed_attributes = nil, broadcast_metadata: nil)
    payload = { conversation: self, notifiable_assignee_change: notifiable_assignee_change?,
                changed_attributes: changed_attributes, performed_by: Current.executed_by }
    payload[:broadcast_metadata] = broadcast_metadata unless broadcast_metadata.nil?
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, **payload)
  end

  def set_unread_count_deletion_data
    @unread_count_deletion_data = {
      id: id,
      account_id: account_id,
      inbox_id: inbox_id,
      assignee_id: assignee_id,
      team_id: team_id,
      cached_label_list: cached_label_list
    }
  end

  def conversation_status_changed_to_open?
    return false unless open?

    # saved_change_to_status? method only works in case of update
    true if previous_changes.key?(:id) || saved_change_to_status?
  end

  def create_label_change(user_name)
    return unless user_name

    previous_labels, current_labels = previous_changes[:label_list]
    return unless (previous_labels.is_a? Array) && (current_labels.is_a? Array)

    create_label_added(user_name, current_labels - previous_labels)
    create_label_removed(user_name, previous_labels - current_labels)
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

Conversation.include_mod_with('Audit::Conversation')
Conversation.include_mod_with('Concerns::Conversation')
Conversation.prepend_mod_with('Conversation')
