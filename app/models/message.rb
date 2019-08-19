class Message < ApplicationRecord
  include Events::Types

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :conversation_id, presence: true

  enum message_type: [ :incoming, :outgoing, :activity ]
  enum status: [ :sent, :delivered, :read, :failed ]

  scope :chat, -> { where.not(message_type: :activity, private: true) }
  default_scope { order(created_at: :asc) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :user, required: false

  has_one :attachment, dependent: :destroy, autosave: true

  after_create :send_reply,
               :dispatch_event,
               :reopen_conversation

  def channel_token
    @token ||= inbox.channel.try(:page_access_token)
  end


  def push_event_data
    data = attributes.merge(created_at: created_at.to_i,
                     message_type: message_type_before_type_cast,
                    conversation_id: conversation.display_id)
    data.merge!({attachment: attachment.push_event_data}) if self.attachment
    data.merge!({sender: user.push_event_data}) if self.user
    data
  end

  private

  def dispatch_event

    $dispatcher.dispatch(MESSAGE_CREATED, Time.zone.now, message: self) unless self.conversation.messages.count == 1

    if outgoing? && self.conversation.messages.outgoing.count == 1
      $dispatcher.dispatch(FIRST_REPLY_CREATED, Time.zone.now, message: self)
    end
  end

  def outgoing_message_from_chatwoot?
    #messages sent directly from chatwoot won't have fb_id.
    outgoing? && !fb_id
  end

  def reopen_lock
    if incoming? && self.conversation.locked?
      self.conversation.unlock!
    end
  end

  def send_reply
    if !private && outgoing_message_from_chatwoot? && inbox.channel.class.to_s == "FacebookPage"
      Bot.deliver(delivery_params, access_token: channel_token)
    end
  end

  def delivery_params
    if twenty_four_hour_window_over?
      { recipient: {id: conversation.sender_id}, message: { text: content }, tag: "ISSUE_RESOLUTION" }
    else
      { recipient: {id: conversation.sender_id}, message: { text: content }}
    end
  end

  def twenty_four_hour_window_over?
    #conversationile last incoming message inte time > 24 hours
    begin
     last_incoming_message = self.conversation.messages.incoming.last
     is_after_24_hours = (Time.diff(last_incoming_message.try(:created_at) || Time.now, Time.now, '%h')[:diff]).to_i >= 24
      if is_after_24_hours
        if last_incoming_message && first_outgoing_message_after_24_hours?(last_incoming_message.id)
          return false
        else
          return true
        end
      else
        return false
      end
    rescue => e
      false
    end
  end

  def first_outgoing_message_after_24_hours?(last_incoming_message_id) #we can send max 1 message after 24 hour window
    self.conversation.messages.outgoing.where("id > ?", last_incoming_message_id).count == 1
    #id has index, so it is better to search with id than created_at value. Anyway id is also created in the same order as created_at
  end

  def reopen_conversation
    if incoming? && self.conversation.resolved?
      self.conversation.toggle_status
      $dispatcher.dispatch(CONVERSATION_REOPENED, Time.zone.now, conversation: self.conversation)
    end
  end
end
