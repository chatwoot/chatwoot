class Chatbots::CallbacksController < ApplicationController
  def update_status
    @chatbot = Chatbot.find_by(id: params[:id])
    return unless @chatbot

    if params[:result] == 'success'
      @chatbot.update(status: 'Enabled')
    else
      @chatbot.update(status: 'Failed')
    end
  end

  def query_reply
    conversation = Conversation.find_by(id: params[:conversation_id])
    bot_message = params[:result]
    if ["I don't know", "I don't know.", 'No matched documents found'].include?(bot_message)
      bot_message = "Sorry, but I don't have a relevant answer. Someone from our team will join the conversation shortly to assist you."
      conversation.update!(chatbot_status: 'Disabled')
    end
    MessageTemplates::Template::ChatbotReply.new(conversation: conversation).perform(bot_message)
  end
end
