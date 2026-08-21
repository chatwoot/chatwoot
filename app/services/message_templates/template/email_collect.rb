class MessageTemplates::Template::EmailCollect
  pattr_initialize [:conversation!]

  def self.perform_after_handoff_if_applicable(conversation)
    # Assignment can finish in the handoff commit callback. Read and lock a fresh row so
    # the prompt uses the final assignee and concurrent handoff paths cannot create duplicates.
    Conversation.transaction do
      locked_conversation = Conversation.lock.find_by(id: conversation.id)
      next unless locked_conversation && collectable_after_handoff?(locked_conversation)

      new(conversation: locked_conversation).perform
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  def self.collectable_after_handoff?(conversation)
    conversation.assignee_id.blank? &&
      conversation.campaign.blank? &&
      email_collectable?(conversation)
  end
  private_class_method :collectable_after_handoff?

  def self.email_collectable?(conversation)
    conversation.inbox.web_widget? &&
      conversation.inbox.enable_email_collect? &&
      conversation.contact.email.blank? &&
      !conversation.messages.exists?(content_type: :input_email)
  end
  private_class_method :email_collectable?

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(ways_to_reach_you_message_params)
      conversation.messages.create!(email_input_box_template_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def ways_to_reach_you_message_params
    content = I18n.t('conversations.templates.ways_to_reach_you_message_body',
                     account_name: account.name)

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end

  def email_input_box_template_message_params
    content = I18n.t('conversations.templates.email_input_box_message_body',
                     account_name: account.name)

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_email,
      content: content
    }
  end
end
