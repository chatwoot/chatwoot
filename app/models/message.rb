# == Schema Information
#
# Table name: messages
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  content               :text
#  content_attributes    :json
#  content_type          :integer          default("text"), not null
#  external_source_ids   :jsonb
#  message_type          :integer          not null
#  private               :boolean          default(FALSE)
#  sender_type           :string
#  status                :integer          default("sent")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  conversation_id       :integer          not null
#  inbox_id              :integer          not null
#  sender_id             :bigint
#  source_id             :string
#
# Indexes
#
#  index_messages_on_account_id                         (account_id)
#  index_messages_on_account_id_and_inbox_id            (account_id,inbox_id)
#  index_messages_on_additional_attributes_campaign_id  (((additional_attributes -> 'campaign_id'::text))) USING gin
#  index_messages_on_content                            (content) USING gin
#  index_messages_on_conversation_id                    (conversation_id)
#  index_messages_on_inbox_id                           (inbox_id)
#  index_messages_on_sender_type_and_sender_id          (sender_type,sender_id)
#  index_messages_on_source_id                          (source_id)
#

class Message < ApplicationRecord
  include MessageFilterHelpers
  include Liquidable
  NUMBER_OF_PERMITTED_ATTACHMENTS = 15

  before_validation :ensure_content_type

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :conversation_id, presence: true
  validates_with ContentAttributeValidator
  validates :content_type, presence: true
  validates :content, length: { maximum: 150_000 }

  # when you have a temperory id in your frontend and want it echoed back via action cable
  attr_accessor :echo_id

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
    incoming_email: 8,
    input_csat: 9,
    integrations: 10
  }
  enum status: { sent: 0, delivered: 1, read: 2, failed: 3 }
  # [:submitted_email, :items, :submitted_values] : Used for bot message types
  # [:email] : Used by conversation_continuity incoming email messages
  # [:in_reply_to] : Used to reply to a particular tweet in threads
  # [:deleted] : Used to denote whether the message was deleted by the agent
  # [:external_created_at] : Can specify if the message was created at a different timestamp externally
  # [:external_error : Can specify if the message creation failed due to an error at external API
  store :content_attributes, accessors: [:submitted_email, :items, :submitted_values, :email, :in_reply_to, :deleted,
                                         :external_created_at, :story_sender, :story_id, :external_error,
                                         :translations], coder: JSON

  store :external_source_ids, accessors: [:slack], coder: JSON, prefix: :external_source_id

  # .succ is a hack to avoid https://makandracards.com/makandra/1057-why-two-ruby-time-objects-are-not-equal-although-they-appear-to-be
  scope :unread_since, ->(datetime) { where('EXTRACT(EPOCH FROM created_at) > (?)', datetime.to_i.succ) }
  scope :chat, -> { where.not(message_type: :activity).where(private: false) }
  scope :non_activity_messages, -> { where.not(message_type: :activity).reorder('id desc') }
  scope :today, -> { where("date_trunc('day', created_at) = ?", Date.current) }

  # TODO: Get rid of default scope
  # https://stackoverflow.com/a/1834250/939299
  # if you want to change order, use `reorder`
  default_scope { order(created_at: :asc) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation, touch: true

  # FIXME: phase out user and contact after 1.4 since the info is there in sender
  belongs_to :user, required: false
  belongs_to :contact, required: false
  belongs_to :sender, polymorphic: true, required: false

  has_many :attachments, dependent: :destroy, autosave: true, before_add: :validate_attachments_limit
  has_one :csat_survey_response, dependent: :destroy_async
  has_many :notifications, as: :primary_actor, dependent: :destroy_async

  after_create_commit :execute_after_create_commit_callbacks

  after_update_commit :dispatch_update_event

  def channel_token
    @token ||= inbox.channel.try(:page_access_token)
  end

  def push_event_data
    data = attributes.merge(
      created_at: created_at.to_i,
      message_type: message_type_before_type_cast,
      conversation_id: conversation.display_id,
      conversation: {
        assignee_id: conversation.assignee_id,
        unread_count: conversation.unread_incoming_messages.count
      }
    )
    data.merge!(echo_id: echo_id) if echo_id.present?
    data.merge!(attachments: attachments.map(&:push_event_data)) if attachments.present?
    merge_sender_attributes(data)
  end

  # TODO: We will be removing this code after instagram_manage_insights is implemented
  # Better logic is to listen to webhook and remove stories proactively rather than trying
  # a fetch every time a message is returned
  def validate_instagram_story
    inbox.channel.fetch_instagram_story_link(self)
    # we want to reload the message in case the story has expired and data got removed
    reload
  end

  def merge_sender_attributes(data)
    data.merge!(sender: sender.push_event_data) if sender && !sender.is_a?(AgentBot)
    data.merge!(sender: sender.push_event_data(inbox)) if sender.is_a?(AgentBot)
    data
  end

  def webhook_data
    data = {
      account: account.webhook_data,
      additional_attributes: additional_attributes,
      content_attributes: content_attributes,
      content_type: content_type,
      content: content,
      conversation: conversation.webhook_data,
      created_at: created_at,
      id: id,
      inbox: inbox.webhook_data,
      message_type: message_type,
      private: private,
      sender: sender.try(:webhook_data),
      source_id: source_id
    }
    data.merge!(attachments: attachments.map(&:push_event_data)) if attachments.present?
    data
  end

  def content
    # move this to a presenter
    return self[:content] if !input_csat? || inbox.web_widget?

    I18n.t('conversations.survey.response', link: "#{ENV.fetch('FRONTEND_URL', nil)}/survey/responses/#{conversation.uuid}")
  end

  def email_notifiable_message?
    return false if private?
    return false if %w[outgoing template].exclude?(message_type)
    return false if template? && %w[input_csat text].exclude?(content_type)

    true
  end

  def valid_first_reply?
    outgoing? && human_response? && not_created_by_automation? && !private?
  end

  private

  def ensure_content_type
    self.content_type ||= Message.content_types[:text]
  end

  def execute_after_create_commit_callbacks
    # rails issue with order of active record callbacks being executed https://github.com/rails/rails/issues/20911
    reopen_conversation
    notify_via_mail
    set_conversation_activity
    dispatch_create_events
    send_reply
    execute_message_template_hooks
    update_contact_activity
  end

  def update_contact_activity
    sender.update(last_activity_at: DateTime.now) if sender.is_a?(Contact)
  end

  def human_response?
    # given the checks are already in place, we need not query
    # the database again to check if the message is created by a human
    # we can just see if the first_reply is recorded or not
    # if it is record, we can just return false
    return false if conversation.first_reply_created_at.present?

    # if the sender is not a user, it's not a human response
    return false unless sender.is_a?(User)

    # if automation rule id is present, it's not a human response
    # if campaign id is present, it's not a human response
    # this check already happens in `not_created_by_automation` but added here for the sake of brevity
    # also the purity of this method is intact, and can be relied on this solely
    return false if content_attributes['automation_rule_id'].present? || additional_attributes['campaign_id'].present?

    # adding this condition again to ensure if the first_reply_created_at is not present
    return false if conversation.messages.outgoing
                                .where.not(sender_type: 'AgentBot')
                                .where.not(private: true)
                                .where("(additional_attributes->'campaign_id') is null").count > 1

    true
  end

  def not_created_by_automation?
    content_attributes['automation_rule_id'].blank?
  end

  def dispatch_create_events
    Rails.configuration.dispatcher.dispatch(MESSAGE_CREATED, Time.zone.now, message: self, performed_by: Current.executed_by)
    if valid_first_reply?
      Rails.configuration.dispatcher.dispatch(FIRST_REPLY_CREATED, Time.zone.now, message: self, performed_by: Current.executed_by)
    end
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(MESSAGE_UPDATED, Time.zone.now, message: self, performed_by: Current.executed_by)
  end

  def send_reply
    # FIXME: Giving it few seconds for the attachment to be uploaded to the service
    # active storage attaches the file only after commit
    attachments.blank? ? ::SendReplyJob.perform_later(id) : ::SendReplyJob.set(wait: 2.seconds).perform_later(id)
  end

  def reopen_conversation
    return if conversation.muted?
    return unless incoming?

    conversation.open! if conversation.snoozed?

    reopen_resolved_conversation if conversation.resolved?
  end

  def reopen_resolved_conversation
    # mark resolved bot conversation as pending to be reopened by bot processor service
    if conversation.inbox.active_bot?
      conversation.pending!
    else
      conversation.open!
    end
  end

  def execute_message_template_hooks
    ::MessageTemplates::HookExecutionService.new(message: self).perform
  end

  def email_notifiable_webwidget?
    inbox.web_widget? && inbox.channel.continuity_via_email
  end

  def email_notifiable_api_channel?
    inbox.api? && inbox.account.feature_enabled?('email_continuity_on_api_channel')
  end

  def email_notifiable_channel?
    email_notifiable_webwidget? || %w[Email].include?(inbox.inbox_type) || email_notifiable_api_channel?
  end

  def can_notify_via_mail?
    return unless email_notifiable_message?
    return unless email_notifiable_channel?
    return if conversation.contact.email.blank?

    true
  end

  def notify_via_mail
    return unless can_notify_via_mail?

    trigger_notify_via_mail
  end

  def trigger_notify_via_mail
    return EmailReplyWorker.perform_in(1.second, id) if inbox.inbox_type == 'Email'

    # will set a redis key for the conversation so that we don't need to send email for every new message
    # last few messages coupled together is sent every 2 minutes rather than one email for each message
    # if redis key exists there is an unprocessed job that will take care of delivering the email
    return if Redis::Alfred.get(conversation_mail_key).present?

    Redis::Alfred.setex(conversation_mail_key, id)
    ConversationReplyEmailWorker.perform_in(2.minutes, conversation.id, id)
  end

  def conversation_mail_key
    format(::Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id)
  end

  def validate_attachments_limit(_attachment)
    errors.add(:attachments, message: 'exceeded maximum allowed') if attachments.size >= NUMBER_OF_PERMITTED_ATTACHMENTS
  end

  def set_conversation_activity
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(last_activity_at: created_at)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
