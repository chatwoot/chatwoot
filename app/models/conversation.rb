# == Schema Information
#
# Table name: conversations
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  agent_last_seen_at    :datetime
#  contact_last_seen_at  :datetime
#  identifier            :string
#  last_activity_at      :datetime         not null
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
#  index_conversations_on_account_id                 (account_id)
#  index_conversations_on_account_id_and_display_id  (account_id,display_id) UNIQUE
#  index_conversations_on_campaign_id                (campaign_id)
#  index_conversations_on_contact_inbox_id           (contact_inbox_id)
#  index_conversations_on_team_id                    (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (contact_inbox_id => contact_inboxes.id)
#  fk_rails_...  (team_id => teams.id)
#

class Conversation < ApplicationRecord
  include Labelable
  include AssignmentHandler
  include RoundRobinHandler

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  before_validation :validate_additional_attributes

  enum status: { open: 0, resolved: 1, bot: 2 }

  scope :latest, -> { order(last_activity_at: :desc) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :contact
  belongs_to :contact_inbox
  belongs_to :team, optional: true
  belongs_to :campaign, optional: true

  has_many :messages, dependent: :destroy, autosave: true
  has_one :csat_survey_response, dependent: :destroy
  has_many :notifications, as: :primary_actor, dependent: :destroy

  before_create :set_bot_conversation

  # wanted to change this to after_update commit. But it ended up creating a loop
  # reinvestigate in future and identity the implications
  after_update :notify_status_change, :create_activity
  after_create_commit :notify_conversation_creation, :queue_conversation_auto_resolution_job
  after_commit :set_display_id, unless: :display_id?

  delegate :auto_resolve_duration, to: :account

  def can_reply?
    return true unless inbox&.channel&.has_24_hour_messaging_window?

    last_incoming_message = messages.incoming.last

    return false if last_incoming_message.nil?

    Time.current < last_incoming_message.created_at + 24.hours
  end

  def update_assignee(agent = nil)
    update!(assignee: agent)
  end

  def toggle_status
    # FIXME: implement state machine with aasm
    self.status = open? ? :resolved : :open
    self.status = :open if bot?
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
    return false if self_assign?(assignee_id)
    return false unless saved_change_to_assignee_id?
    return false if assignee_id.blank?

    true
  end

  private

  def validate_additional_attributes
    self.additional_attributes = {} unless additional_attributes.is_a?(Hash)
  end

  def set_bot_conversation
    self.status = :bot if inbox.agent_bot_inbox&.active? || inbox.hooks.pluck(:app_id).include?('dialogflow')
  end

  def notify_conversation_creation
    dispatcher_dispatch(CONVERSATION_CREATED)
  end

  def queue_conversation_auto_resolution_job
    return unless auto_resolve_duration

    AutoResolveConversationsJob.set(wait_until: (last_activity_at || created_at) + auto_resolve_duration.days).perform_later(id)
  end

  def self_assign?(assignee_id)
    assignee_id.present? && Current.user&.id == assignee_id
  end

  def set_display_id
    reload
  end

  def create_activity
    user_name = Current.user.name if Current.user.present?
    status_change_activity(user_name) if saved_change_to_status?
    create_label_change(user_name) if saved_change_to_label_list?
  end

  def status_change_activity(user_name)
    create_status_change_message(user_name)
    queue_conversation_auto_resolution_job if open?
  end

  def activity_message_params(content)
    { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
  end

  def notify_status_change
    {
      CONVERSATION_OPENED => -> { saved_change_to_status? && open? },
      CONVERSATION_RESOLVED => -> { saved_change_to_status? && resolved? },
      CONVERSATION_STATUS_CHANGED => -> { saved_change_to_status? },
      CONVERSATION_READ => -> { saved_change_to_contact_last_seen_at? },
      CONVERSATION_CONTACT_CHANGED => -> { saved_change_to_contact_id? }
    }.each do |event, condition|
      condition.call && dispatcher_dispatch(event)
    end
  end

  def dispatcher_dispatch(event_name)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, conversation: self)
  end

  def conversation_status_changed_to_open?
    return false unless open?
    # saved_change_to_status? method only works in case of update
    return true if previous_changes.key?(:id) || saved_change_to_status?
  end

  def create_status_change_message(user_name)
    content = if user_name
                I18n.t("conversations.activity.status.#{status}", user_name: user_name)
              elsif resolved?
                I18n.t('conversations.activity.status.auto_resolved', duration: auto_resolve_duration)
              end

    messages.create(activity_message_params(content)) if content
  end

  def create_label_change(user_name)
    return unless user_name

    previous_labels, current_labels = previous_changes[:label_list]
    return unless (previous_labels.is_a? Array) && (current_labels.is_a? Array)

    create_label_added(user_name, current_labels - previous_labels)
    create_label_removed(user_name, previous_labels - current_labels)
  end

  def create_label_added(user_name, labels = [])
    return unless labels.size.positive?

    params = { user_name: user_name, labels: labels.join(', ') }
    content = I18n.t('conversations.activity.labels.added', **params)

    messages.create(activity_message_params(content))
  end

  def create_label_removed(user_name, labels = [])
    return unless labels.size.positive?

    params = { user_name: user_name, labels: labels.join(', ') }
    content = I18n.t('conversations.activity.labels.removed', **params)

    messages.create(activity_message_params(content))
  end

  def create_muted_message
    return unless Current.user

    params = { user_name: Current.user.name }
    content = I18n.t('conversations.activity.muted', **params)

    messages.create(activity_message_params(content))
  end

  def create_unmuted_message
    return unless Current.user

    params = { user_name: Current.user.name }
    content = I18n.t('conversations.activity.unmuted', **params)

    messages.create(activity_message_params(content))
  end

  def mute_key
    format(Redis::RedisKeys::CONVERSATION_MUTE_KEY, id: id)
  end

  def mute_period
    6.hours
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);"
  end
end
