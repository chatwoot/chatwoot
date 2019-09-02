class Conversation < ApplicationRecord
  include Events::Types

  validates :account_id, presence: true
  validates :inbox_id, presence: true

  enum status: [ :open, :resolved ]

  scope :latest, -> { order(created_at: :desc) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned_to, -> (agent) { where(assignee_id: agent.id) }

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

  def update_assignee(agent=nil)
    self.assignee = agent
    self.save!
  end

  def update_labels(labels=nil)
    self.label_list = labels
    self.save!
  end

  def toggle_status
    if open?
      self.status = :resolved
    else
      self.status = :open
    end
    self.save! ? true : false
  end

  def lock!
    self.locked = true
    self.save!
  end

  def unlock!
    self.locked = false
    self.save!
  end

  def unread_messages
    # +1 is a hack to avoid https://makandracards.com/makandra/1057-why-two-ruby-time-objects-are-not-equal-although-they-appear-to-be
    # ente budhiparamaya neekam kandit entu tonunu?
    messages.where("EXTRACT(EPOCH FROM created_at) > (?)", agent_last_seen_at.to_i + 1)
  end

  def unread_incoming_messages
    messages.incoming.where("EXTRACT(EPOCH FROM created_at) > (?)", agent_last_seen_at.to_i + 1)
  end

  def push_event_data
    last_message = messages.chat.last
    {
      meta: {
        sender: sender.push_event_data,
        assignee: assignee
      },
      id: display_id,
      messages: [last_message.try(:push_event_data) ],
      inbox_id: inbox_id,
      status: status_before_type_cast.to_i,
      timestamp: created_at.to_i,
      # user_last_seen_at: user_last_seen_at.to_i,
      # agent_last_seen_at: agent_last_seen_at.to_i,
      # unread_count: unread_incoming_messages.count
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
    if assignee_id_changed? && assignee_id.present? && !self_assign?(assignee_id)
      AssignmentMailer.conversation_assigned(self, self.assignee).deliver
    end
  end

  def self_assign?(assignee_id)
    return false unless Current.user
    Current.user.id == assignee_id
  end

  def set_display_id
    self.display_id = loop do
      disp_id = self.account.conversations.maximum("display_id").to_i + 1
      break disp_id unless account.conversations.exists?(display_id: disp_id)
    end
  end

  def create_activity
    if status_changed? && Current.user #to prevent error when conversation is reopened by customer itself by sending a new message
      if resolved?
        content = "Conversation was marked resolved by #{Current.user.try(:name)}"
      else
        content = "Conversation was reopened by #{Current.user.try(:name)}"
      end
      self.messages.create(activity_message_params(content))
    end

    if assignee_id_changed? && Current.user
      if assignee_id
        content = "Assigned to #{assignee.name} by #{Current.user.try(:name)}"
      else
        content = "Conversation unassigned by #{Current.user.try(:name)}"
      end
      self.messages.create(activity_message_params(content))
    end
  end

  def activity_message_params content
    {
      account_id: account_id,
      inbox_id: inbox_id,
      message_type: :activity,
      content: content
    }
  end

  def notify_status_change
    if status_changed?
      if resolved? && assignee.present?
        $dispatcher.dispatch(CONVERSATION_RESOLVED, Time.zone.now, conversation: self)
      end
    end
    if user_last_seen_at_changed?
      $dispatcher.dispatch(CONVERSATION_READ, Time.zone.now, conversation: self)
    end
    if locked_changed?
      $dispatcher.dispatch(CONVERSATION_LOCK_TOGGLE, Time.zone.now, conversation: self)
    end
    if assignee_id_changed?
      $dispatcher.dispatch(ASSIGNEE_CHANGED, Time.zone.now, conversation: self)
    end
  end


  def run_round_robin
    if true #conversation.account.has_feature?(round_robin)
      if true #conversation.account.round_robin_enabled?
        unless self.assignee #if not already assigned
          new_assignee = self.inbox.next_available_agent
          self.update_assignee(new_assignee) if new_assignee
        end
      end
    end
  end
end
