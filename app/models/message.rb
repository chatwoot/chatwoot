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
#  sender_type        :string
#  status             :integer          default("sent")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#  conversation_id    :integer          not null
#  inbox_id           :integer          not null
#  sender_id          :bigint
#  source_id          :string
#
# Indexes
#
#  index_messages_on_account_id                 (account_id)
#  index_messages_on_conversation_id            (conversation_id)
#  index_messages_on_inbox_id                   (inbox_id)
#  index_messages_on_sender_type_and_sender_id  (sender_type,sender_id)
#  index_messages_on_source_id                  (source_id)
#

class Message < ApplicationRecord
  include Events::Types

  NUMBER_OF_PERMITTED_ATTACHMENTS = 15

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :conversation_id, presence: true
  validates_with ContentAttributeValidator

  enum message_type: { incoming: 0, outgoing: 1, activity: 2, template: 3 }
  enum content_type: {
    text: 0,
    input_text: 1,
    input_textarea: 2,
    input_email: 3,
    input_select: 4,
    cards: 5,
    form: 6,
    article: 7,
    incoming_email: 8
  }
  enum status: { sent: 0, delivered: 1, read: 2, failed: 3 }
  store :content_attributes, accessors: [:submitted_email, :items, :submitted_values, :email], coder: JSON

  # .succ is a hack to avoid https://makandracards.com/makandra/1057-why-two-ruby-time-objects-are-not-equal-although-they-appear-to-be
  scope :unread_since, ->(datetime) { where('EXTRACT(EPOCH FROM created_at) > (?)', datetime.to_i.succ) }
  scope :chat, -> { where.not(message_type: :activity).where(private: false) }
  default_scope { order(created_at: :asc) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation, touch: true

  # FIXME: phase out user and contact after 1.4 since the info is there in sender
  belongs_to :user, required: false
  belongs_to :contact, required: false
  belongs_to :sender, polymorphic: true, required: false

  has_many :attachments, dependent: :destroy, autosave: true, before_add: :validate_attachments_limit

  after_create :reopen_conversation,
               :notify_via_mail

  after_create_commit :execute_after_create_commit_callbacks

  after_update :dispatch_update_event

  def channel_token
    @token ||= inbox.channel.try(:page_access_token)
  end

  def push_event_data
    data = attributes.merge(
      created_at: created_at.to_i,
      message_type: message_type_before_type_cast,
      conversation_id: conversation.display_id
    )
    data.merge!(attachments: attachments.map(&:push_event_data)) if attachments.present?
    data.merge!(sender: sender.push_event_data) if sender && !sender.is_a?(AgentBot)
    data.merge!(sender: sender.push_event_data(inbox)) if sender&.is_a?(AgentBot)
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
      content_type: content_type,
      content_attributes: content_attributes,
      source_id: source_id,
      sender: sender.try(:webhook_data),
      inbox: inbox.webhook_data,
      conversation: conversation.webhook_data,
      account: account.webhook_data
    }
  end

  private

  def execute_after_create_commit_callbacks
    # rails issue with order of active record callbacks being executed
    # https://github.com/rails/rails/issues/20911
    dispatch_create_events
    send_reply
    execute_message_template_hooks
  end

  def dispatch_create_events
    Rails.configuration.dispatcher.dispatch(MESSAGE_CREATED, Time.zone.now, message: self)

    if outgoing? && conversation.messages.outgoing.count == 1
      Rails.configuration.dispatcher.dispatch(FIRST_REPLY_CREATED, Time.zone.now, message: self)
    end
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(MESSAGE_UPDATED, Time.zone.now, message: self)
  end

  def send_reply
    channel_name = conversation.inbox.channel.class.to_s
    if channel_name == 'Channel::FacebookPage'
      ::Facebook::SendOnFacebookService.new(message: self).perform
    elsif channel_name == 'Channel::TwitterProfile'
      ::Twitter::SendOnTwitterService.new(message: self).perform
    elsif channel_name == 'Channel::TwilioSms'
      ::Twilio::SendOnTwilioService.new(message: self).perform
    end
  end

  def reopen_conversation
    conversation.open! if incoming? && conversation.resolved? && !conversation.muted?
  end

  def execute_message_template_hooks
    ::MessageTemplates::HookExecutionService.new(message: self).perform
  end

  def notify_via_mail
    if Redis::Alfred.get(conversation_mail_key).nil? && conversation.contact.email? && outgoing?
      # set a redis key for the conversation so that we don't need to send email for every
      # new message that comes in and we dont enque the delayed sidekiq job for every message
      Redis::Alfred.setex(conversation_mail_key, Time.zone.now)

      # Since this is live chat, send the email after few minutes so the only one email with
      # last few messages coupled together is sent rather than email for each message
      ConversationReplyEmailWorker.perform_in(2.minutes, conversation.id, Time.zone.now)
    end
  end

  def conversation_mail_key
    format(::Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id)
  end

  def validate_attachments_limit(_attachment)
    errors.add(attachments: 'exceeded maximum allowed') if attachments.size >= NUMBER_OF_PERMITTED_ATTACHMENTS
  end
end
