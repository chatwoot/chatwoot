# frozen_string_literal: true

class Integrations::Widget::IncomingMessageBuilder
  #  params = {
  #   contact_id: 1,
  #   inbox_id: 1,
  #   content: "Hello world"
  # }

  attr_accessor :options, :message

  def initialize(options)
    @options = options
  end

  def perform
    ActiveRecord::Base.transaction do
      build_message
    end
  end

  private

  def inbox
    @inbox ||= Inbox.find(options[:inbox_id])
  end

  def contact
    @contact ||= Contact.find(options[:contact_id])
  end

  def conversation
    @conversation ||= Conversation.find_by(conversation_params) || Conversation.create!(conversation_params)
  end

  def build_message
    @message = conversation.messages.new(message_params)
    @message.save!
  end

  def conversation_params
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: options[:contact_id]
    }
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: 0,
      content: options[:content],
      sender: contact
    }
  end
end
