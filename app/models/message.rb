class Message < ApplicationRecord
  include Events::Types

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :conversation_id, presence: true

  enum message_type: [ :incoming, :outgoing, :activity ]
  enum status: [ :sent, :delivered, :read, :failed ]

  scope :chat, -> { where(message_type: :activity, private: true) }
  default_scope { order(created_at: :asc) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :user, required: false

  has_one :attachment, dependent: :destroy, autosave: true

  after_create :reopen_conversation,
               :dispatch_event,
               :send_reply


  def channel_token
    @token ||= inbox.channel.try(:page_access_token)
  end


  def push_event_data
    data = attributes.merge(
      created_at: created_at.to_i,
      message_type: message_type_before_type_cast,
      conversation_id: conversation.display_id
    )
    data.merge!(attachment: attachment.push_event_data) if self.attachment
    data.merge!(sender: user.push_event_data) if self.user
    data
  end

  private

  def dispatch_event
    $dispatcher.dispatch(MESSAGE_CREATED, Time.zone.now, message: self) unless self.conversation.messages.count == 1

    if outgoing? && self.conversation.messages.outgoing.count == 1
      $dispatcher.dispatch(FIRST_REPLY_CREATED, Time.zone.now, message: self)
    end
  end

  def send_reply
    ::Facebook::SendReplyService.new(message: self).perform
  end

  def reopen_conversation
    if incoming? && self.conversation.resolved?
      self.conversation.toggle_status
      $dispatcher.dispatch(CONVERSATION_REOPENED, Time.zone.now, conversation: self.conversation)
    end
  end
end
