# frozen_string_literal: true

class Integrations::AnswerWise::OutgoingMessageBuilder
  # TODO: Tweak message params based on the bot vendor and message types.
  # params = {
  #   agent_bot_id: 1,
  #   inbox_id: 1,
  #   conversation_id: 2,
  #   message: {
  #     type: 'text'
  #     content: 'Hello world'
  #   }
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

  def agent_bot
    @agent_bot ||= AgentBot.find(options[:agent_bot_id])
  end

  def inbox
    agent_bot.inboxes.find(options[:inbox_id])
  end

  def conversation
    @conversation ||= inbox.conversations.find(options[:conversation_id])
  end

  def build_message
    @message = conversation.messages.new(message_params)
    @message.save!
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: inbox.id,
      message_type: 1,
      content: options[:message][:content]
      # TODO: Add agent bot as user for this message
    }
  end
end
