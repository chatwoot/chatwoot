# == Schema Information
#
# Table name: conversations
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  agent_last_seen_at    :datetime
#  assignee_last_seen_at :datetime
#  contact_last_seen_at  :datetime
#  custom_attributes     :jsonb
#  identifier            :string
#  last_activity_at      :datetime         not null
#  snoozed_until         :datetime
#  status                :integer          default("open"), not null
#  uuid                  :uuid             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  assignee_id           :integer
#  campaign_id           :bigint
#  contact_id            :bigint
#  contact_inbox_id      :bigint
#  display_id            :integer          not null
#  inbox_id              :integer          not null
#  team_id               :bigint
#
# Indexes
#
#  index_conversations_on_account_id                  (account_id)
#  index_conversations_on_account_id_and_display_id   (account_id,display_id) UNIQUE
#  index_conversations_on_assignee_id_and_account_id  (assignee_id,account_id)
#  index_conversations_on_campaign_id                 (campaign_id)
#  index_conversations_on_contact_inbox_id            (contact_inbox_id)
#  index_conversations_on_last_activity_at            (last_activity_at)
#  index_conversations_on_status_and_account_id       (status,account_id)
#  index_conversations_on_team_id                     (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id) ON DELETE => cascade
#  fk_rails_...  (contact_inbox_id => contact_inboxes.id) ON DELETE => cascade
#  fk_rails_...  (team_id => teams.id) ON DELETE => cascade
#

class Conversation < ApplicationRecord
  include Labelable
  include AssignmentHandler
  include RoundRobinHandler
  include ActivityMessageHandler
  include UrlHelper

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  before_validation :validate_additional_attributes
  validates :additional_attributes, jsonb_attributes_length: true
  validates :custom_attributes, jsonb_attributes_length: true
  validate :validate_referer_url

  enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }

  scope :latest, -> { order(last_activity_at: :desc) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned, -> { where.not(assignee_id: nil) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }
  scope :resolvable, lambda { |auto_resolve_duration|
    return [] if auto_resolve_duration.to_i.zero?

    open.where('last_activity_at < ? ', Time.now.utc - auto_resolve_duration.days)
  }

  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :contact
  belongs_to :contact_inbox
  belongs_to :team, optional: true
  belongs_to :campaign, optional: true

  has_many :mentions, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async, autosave: true
  has_one :csat_survey_response, dependent: :destroy_async
  has_many :notifications, as: :primary_actor, dependent: :destroy

  before_save :ensure_snooze_until_reset
  before_create :mark_conversation_pending_if_bot

  after_update_commit :execute_after_update_commit_callbacks
  after_create_commit :notify_conversation_creation
  after_commit :set_display_id, unless: :display_id?

  delegate :auto_resolve_duration, to: :account

  def can_reply?
    return last_message_less_than_24_hrs? if additional_attributes['type'] == 'instagram_direct_message'

    return true unless inbox&.channel&.has_24_hour_messaging_window?

    return false if last_incoming_message.nil?

    last_message_less_than_24_hrs?
  end

  def last_incoming_message
    messages&.incoming&.last
  end

  def last_message_less_than_24_hrs?
    return false if last_incoming_message.nil?

    Time.current < last_incoming_message.created_at + 24.hours
  end

  def update_assignee(agent = nil)
    update!(assignee: agent)
  end

  def toggle_status
    # FIXME: implement state machine with aasm
    self.status = open? ? :resolved : :open
    self.status = :open if pending? || snoozed?
    save
  end

  def mute!
    resolved!
    Redis::Alfred.setex(mute_key, 1, mute_period)
    create_muted_message
  end

  def unmute!
    Redis::Alfred.delete(mute_key)
    create_unmuted_message
  end

  def muted?
    Redis::Alfred.get(mute_key).present?
  end

  def unread_messages
    messages.unread_since(agent_last_seen_at)
  end

  def unread_incoming_messages
    messages.incoming.unread_since(agent_last_seen_at)
  end

  def push_event_data
    Conversations::EventDataPresenter.new(self).push_data
  end

  def lock_event_data
    Conversations::EventDataPresenter.new(self).lock_data
  end

  def webhook_data
    Conversations::EventDataPresenter.new(self).push_data
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

  private

  def execute_after_update_commit_callbacks
    notify_status_change
    create_activity
    notify_conversation_updation
  end

  def ensure_snooze_until_reset
    self.snoozed_until = nil unless snoozed?
  end

  def validate_additional_attributes
    self.additional_attributes = {} unless additional_attributes.is_a?(Hash)
  end

  def mark_conversation_pending_if_bot
    # TODO: make this an inbox config instead of assuming bot conversations should start as pending
    self.status = :pending if inbox.agent_bot_inbox&.active? || inbox.hooks.pluck(:app_id).include?('dialogflow')
  end

  def notify_conversation_creation
    dispatcher_dispatch(CONVERSATION_CREATED)
  end

  def notify_conversation_updation
    return unless previous_changes.keys.present? && (previous_changes.keys & %w[team_id assignee_id status snoozed_until
                                                                                custom_attributes]).present?

    dispatcher_dispatch(CONVERSATION_UPDATED, previous_changes)
  end

  def self_assign?(assignee_id)
    assignee_id.present? && Current.user&.id == assignee_id
  end

  def set_display_id
    reload
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

    create_label_added(user_name, current_labels - previous_labels)
    create_label_removed(user_name, previous_labels - current_labels)
  end

  def mute_key
    format(Redis::RedisKeys::CONVERSATION_MUTE_KEY, id: id)
  end

  def mute_period
    6.hours
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
