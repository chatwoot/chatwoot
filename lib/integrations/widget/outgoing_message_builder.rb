# frozen_string_literal: true

class Integrations::Widget::OutgoingMessageBuilder
  # params = {
  #   user_id: 1,
  #   inbox_id: 1,
  #   content: "Hello world",
  #   conversation_id: 2
  # }

  attr_accessor :options, :message

  def initialize(options)
    @options = options
  end

  def perform
    ActiveRecord::Base.transaction do
      build_conversation
      build_message
    end
  end

  private

  def inbox
    @inbox ||= Inbox.find(options[:inbox_id])
  end

  def user
    @user ||= Contact.find(options[:user_id])
  end

  def build_conversation
    @conversation ||= Conversation.find(options[:conversation_id])
  end

  def build_message
    @message = @conversation.messages.new(message_params)
    @message.save!
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: 1,
      content: options[:content],
      sender: user
    }
  end
end
