# == Schema Information
#
# Table name: conversations
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  agent_last_seen_at    :datetime
#  identifier            :string
#  locked                :boolean          default(FALSE)
#  status                :integer          default("open"), not null
#  user_last_seen_at     :datetime
#  uuid                  :uuid             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  assignee_id           :integer
#  contact_id            :bigint
#  contact_inbox_id      :bigint
#  display_id            :integer          not null
#  inbox_id              :integer          not null
#
# Indexes
#
#  index_conversations_on_account_id                 (account_id)
#  index_conversations_on_account_id_and_display_id  (account_id,display_id) UNIQUE
#  index_conversations_on_contact_inbox_id           (contact_inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_inbox_id => contact_inboxes.id)
#

class Conversation < ApplicationRecord
  validates :account_id, presence: true
  validates :inbox_id, presence: true

  enum status: { open: 0, resolved: 1, bot: 2 }

  scope :latest, -> { order(updated_at: :desc) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :contact
  belongs_to :contact_inbox

  has_many :messages, dependent: :destroy, autosave: true

  before_create :set_display_id, unless: :display_id?
  before_create :set_bot_conversation
  after_create_commit :notify_conversation_creation
  after_save :run_round_robin
  # wanted to change this to after_update commit. But it ended up creating a loop
  # reinvestigate in future and identity the implications
  after_update :notify_status_change, :create_activity

  acts_as_taggable_on :labels

  def can_reply?
    return true unless inbox&.channel&.has_24_hour_messaging_window?

    last_incoming_message = messages.incoming.last

    return false if last_incoming_message.nil?

    Time.current < last_incoming_message.created_at + 24.hours
  end

  def update_assignee(agent = nil)
    update!(assignee: agent)
  end

  def update_labels(labels = nil)
    update!(label_list: labels)
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
  end

  def muted?
    !Redis::Alfred.get(mute_key).nil?
  end

  def lock!
    update!(locked: true)
  end

  def unlock!
    update!(locked: false)
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

  def set_bot_conversation
    self.status = :bot if inbox.agent_bot_inbox&.active?
  end

  def notify_conversation_creation
    dispatcher_dispatch(CONVERSATION_CREATED)
  end

  def self_assign?(assignee_id)
    assignee_id.present? && Current.user&.id == assignee_id
  end

  def set_display_id
    self.display_id = loop do
      next_display_id = account.conversations.maximum('display_id').to_i + 1
      break next_display_id unless account.conversations.exists?(display_id: next_display_id)
    end
  end

  def create_activity
    return unless Current.user

    user_name = Current.user&.available_name

    create_status_change_message(user_name) if saved_change_to_status?
    create_assignee_change(user_name) if saved_change_to_assignee_id?
  end

  def activity_message_params(content)
    { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
  end

  def notify_status_change
    {
      CONVERSATION_OPENED => -> { saved_change_to_status? && open? },
      CONVERSATION_RESOLVED => -> { saved_change_to_status? && resolved? },
      CONVERSATION_READ => -> { saved_change_to_user_last_seen_at? },
      CONVERSATION_LOCK_TOGGLE => -> { saved_change_to_locked? },
      ASSIGNEE_CHANGED => -> { saved_change_to_assignee_id? },
      CONVERSATION_CONTACT_CHANGED => -> { saved_change_to_contact_id? }
    }.each do |event, condition|
      condition.call && dispatcher_dispatch(event)
    end
  end

  def dispatcher_dispatch(event_name)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, conversation: self)
  end

  def should_round_robin?
    return false unless inbox.enable_auto_assignment?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end

  def conversation_status_changed_to_open?
    return false unless open?
    # saved_change_to_status? method only works in case of update
    return true if previous_changes.key?(:id) || saved_change_to_status?
  end

  def run_round_robin
    # Round robin kicks in on conversation create & update
    # run it only when conversation status changes to open
    return unless conversation_status_changed_to_open?
    return unless should_round_robin?

    ::RoundRobin::AssignmentService.new(conversation: self).perform
  end

  def create_status_change_message(user_name)
    content = I18n.t("conversations.activity.status.#{status}", user_name: user_name)

    messages.create(activity_message_params(content))
  end

  def create_assignee_change(user_name)
    params = { assignee_name: assignee&.available_name, user_name: user_name }.compact
    key = assignee_id ? 'assigned' : 'removed'
    content = I18n.t("conversations.activity.assignee.#{key}", **params)

    messages.create(activity_message_params(content))
  end

  def mute_key
    format('CONVERSATION::%<id>d::MUTED', id: id)
  end

  def mute_period
    6.hours
  end
end
