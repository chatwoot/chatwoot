class Api::V1::Widget::ChatbotsController < ApplicationController
  def connect_with_team
    conversation_id = Message.find_by(id: params[:message_id]).conversation_id
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.chatbot_attributes['connect_with_team'] == false

    bot_message = Chatbot.find_by(website_token: params[:website_token]).reply_on_connect_with_team || I18n.t('chatbots.reply_on_connect_with_team')
    MessageTemplates::Template::ChatbotReply.new(conversation: conversation).connect_with_team(bot_message)
    conversation.chatbot_attributes['status'] = 'Disabled'
    conversation.chatbot_attributes['connect_with_team'] = false
    conversation.save!
  end
end
