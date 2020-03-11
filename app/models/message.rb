# == Schema Information
#
# Table name: messages
#
#  id                 :integer          not null, primary key
#  content            :text
#  content_attributes :json
#  content_type       :integer          default("text")
#  message_type       :integer          not null
#  private            :boolean          default(FALSE)
#  status             :integer          default("sent")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#  contact_id         :bigint
#  conversation_id    :integer          not null
#  inbox_id           :integer          not null
#  source_id          :string
#  user_id            :integer
#
# Indexes
#
#  index_messages_on_account_id       (account_id)
#  index_messages_on_contact_id       (contact_id)
#  index_messages_on_conversation_id  (conversation_id)
#  index_messages_on_inbox_id         (inbox_id)
#  index_messages_on_source_id        (source_id)
#  index_messages_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#

class Message < ApplicationRecord
  include Events::Types

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :conversation_id, presence: true

  enum message_type: { incoming: 0, outgoing: 1, activity: 2, template: 3 }
  enum content_type: { text: 0, input: 1, input_textarea: 2, input_email: 3 }
  enum status: { sent: 0, delivered: 1, read: 2, failed: 3 }
  store :content_attributes, accessors: [:submitted_email], coder: JSON, prefix: :input

  # .succ is a hack to avoid https://makandracards.com/makandra/1057-why-two-ruby-time-objects-are-not-equal-although-they-appear-to-be
  scope :unread_since, ->(datetime) { where('EXTRACT(EPOCH FROM created_at) > (?)', datetime.to_i.succ) }
  scope :chat, -> { where.not(message_type: :activity).where.not(private: true) }
  default_scope { order(created_at: :asc) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :user, required: false
  belongs_to :contact, required: false

  has_one :attachment, dependent: :destroy, autosave: true

  after_create :reopen_conversation,
               :dispatch_event,
               :send_reply,
               :execute_message_template_hooks,
               :notify_via_mail

  def channel_token
    @token ||= inbox.channel.try(:page_access_token)
  end

  def push_event_data
    data = attributes.merge(
      created_at: created_at.to_i,
      message_type: message_type_before_type_cast,
      conversation_id: conversation.display_id
    )
    data.merge!(attachment: attachment.push_event_data) if attachment
    data.merge!(sender: user.push_event_data) if user
    data
  end

  def reportable?
    incoming? || outgoing?
  end

  def webhook_data
    {
      id: id,
      content: content,
      created_at: created_at,
      message_type: message_type,
      source_id: source_id,
      sender: user.try(:webhook_data),
      contact: contact.try(:webhook_data),
      inbox: inbox.webhook_data,
      conversation: conversation.webhook_data,
      account: account.webhook_data
    }
  end

  private

  def dispatch_event
    Rails.configuration.dispatcher.dispatch(MESSAGE_CREATED, Time.zone.now, message: self)

    if outgoing? && conversation.messages.outgoing.count == 1
      Rails.configuration.dispatcher.dispatch(FIRST_REPLY_CREATED, Time.zone.now, message: self)
    end
  end

  def send_reply
    channel_name = conversation.inbox.channel.class.to_s
    if channel_name == 'Channel::FacebookPage'
      ::Facebook::SendReplyService.new(message: self).perform
    elsif channel_name == 'Channel::TwitterProfile'
      ::Twitter::SendReplyService.new(message: self).perform
    end
  end

  def reopen_conversation
    if incoming? && conversation.resolved?
      conversation.toggle_status
      Rails.configuration.dispatcher.dispatch(CONVERSATION_REOPENED, Time.zone.now, conversation: conversation)
    end
  end

  def execute_message_template_hooks
    ::MessageTemplates::HookExecutionService.new(message: self).perform
  end

  def notify_via_mail
    conversation_mail_key = Redis::Alfred::CONVERSATION_MAILER_KEY % conversation.id
    if Redis::Alfred.get(conversation_mail_key).nil? && conversation.contact.email? && outgoing?
      # set a redis key for the conversation so that we don't need to send email for every
      # new message that comes in and we dont enque the delayed sidekiq job for every message
      Redis::Alfred.setex(conversation_mail_key, Time.zone.now)

      # Since this is live chat, send the email after few minutes so the only one email with
      # last few messages coupled together is sent rather than email for each message
      ConversationReplyEmailWorker.perform_in(2.minutes, conversation.id, Time.zone.now)
    end
  end
end
