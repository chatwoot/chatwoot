class Conversation < ApplicationRecord
  include Events::Types

  validates :account_id, presence: true
  validates :inbox_id, presence: true

  enum status: [:open, :resolved]

  scope :latest, -> { order(created_at: :desc) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :sender, class_name: 'Contact'

  has_many :messages, dependent: :destroy, autosave: true

  before_create :set_display_id, unless: :display_id?

  after_update :notify_status_change,
               :create_activity,
               :send_email_notification_to_assignee

  after_create :send_events, :run_round_robin

  acts_as_taggable_on :labels

  def update_assignee(agent = nil)
    self.assignee = agent
    save!
  end

  def update_labels(labels = nil)
    self.label_list = labels
    save!
  end

  def toggle_status
    self.status = open? ? :resolved : :open
    save! ? true : false
  end

  def lock!
    self.locked = true
    save!
  end

  def unlock!
    self.locked = false
    save!
  end

  def unread_messages
    # +1 is a hack to avoid https://makandracards.com/makandra/1057-why-two-ruby-time-objects-are-not-equal-although-they-appear-to-be
    # ente budhiparamaya neekam kandit entu tonunu?
    messages.where('EXTRACT(EPOCH FROM created_at) > (?)', agent_last_seen_at.to_i + 1)
  end

  def unread_incoming_messages
    messages.incoming.where('EXTRACT(EPOCH FROM created_at) > (?)', agent_last_seen_at.to_i + 1)
  end

  def push_event_data
    {
      meta: { sender: sender.push_event_data, assignee: assignee }, id: display_id,
      messages: [messages.chat.last&.push_event_data], inbox_id: inbox_id, status: status_before_type_cast.to_i,
      timestamp: created_at.to_i, user_last_seen_at: user_last_seen_at.to_i, agent_last_seen_at: agent_last_seen_at.to_i,
      unread_count: unread_incoming_messages.count
    }
  end

  def lock_event_data
    {
      id: display_id,
      locked: locked?
    }
  end

  private

  def dispatch_events
    $dispatcher.dispatch(CONVERSATION_RESOLVED, Time.zone.now, conversation: self)
  end

  def send_events
    $dispatcher.dispatch(CONVERSATION_CREATED, Time.zone.now, conversation: self)
  end

  def send_email_notification_to_assignee
    AssignmentMailer.conversation_assigned(self, assignee).deliver if assignee_id_changed? && assignee_id.present? && !self_assign?(assignee_id)
  end

  def self_assign?(assignee_id)
    return false unless Current.user

    Current.user.id == assignee_id
  end

  def set_display_id
    self.display_id = loop do
      disp_id = account.conversations.maximum('display_id').to_i + 1
      break disp_id unless account.conversations.exists?(display_id: disp_id)
    end
  end

  def create_activity
    return unless Current.user

    user_name = Current.user&.name

    create_status_change_message(user_name) if status_changed?
    create_assignee_change(username) if assignee_id_changed?
  end

  def status_changed_message
    return "Conversation was marked resolved by #{Current.user.try(:name)}" if resolved?

    "Conversation was reopened by #{Current.user.try(:name)}"
  end

  def assignee_changed_message
    return "Assigned to #{assignee.name} by #{Current.user.try(:name)}" if assignee_id

    "Conversation unassigned by #{Current.user.try(:name)}"
  end

  def activity_message_params(content)
    {
      account_id: account_id,
      inbox_id: inbox_id,
      message_type: :activity,
      content: content
    }
  end

  def notify_status_change
    resolve_conversation if status_changed?
    dispatcher_dispatch(CONVERSATION_READ) if user_last_seen_at_changed?
    dispatcher_dispatch(CONVERSATION_LOCK_TOGGLE) if locked_changed?
    dispatcher_dispatch(ASSIGNEE_CHANGED) if assignee_id_changed?
  end

  def resolve_conversation
    if resolved? && assignee.present?
      dispatcher_dispatch(CONVERSATION_RESOLVED)
    end
  end

  def dispatcher_dispatch(event_name)
    $dispatcher.dispatch(event_name, Time.zone.now, conversation: self)
  end

  def run_round_robin
    return unless true # conversation.account.has_feature?(round_robin)
    return unless true # conversation.account.round_robin_enabled?
    return if assignee

    new_assignee = inbox.next_available_agent
    update_assignee(new_assignee) if new_assignee
  end

  def create_status_change_message(user_name)
    content = if resolved?
                "Conversation was marked resolved by #{user_name}"
              else
                "Conversation was reopened by #{user_name}"
              end

    messages.create(activity_message_params(content))
  end

  def create_assignee_change(username)
    content = if assignee_id
                "Assigned to #{assignee.name} by #{username}"
              else
                "Conversation unassigned by #{username}"
              end

    messages.create(activity_message_params(content))
  end

  def resolved_and_assignee?
    resolved? && assignee.present?
  end
end
