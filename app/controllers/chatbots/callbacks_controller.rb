class Chatbots::CallbacksController < ApplicationController
  def update_status
    @chatbot = Chatbot.find_by(id: params[:id])
    return unless @chatbot

    if params[:result] == 'success'
      conversations = Conversation.where(inbox_id: params[:inbox_id])
      conversations.find_each do |conversation|
        updated_attributes = conversation.chatbot_attributes.merge({ id: params[:id], status: 'Enabled', connect_with_team: true })
        conversation.update(chatbot_attributes: updated_attributes)
      end
      @chatbot.update!(status: 'Enabled')
    else
      @chatbot.update!(status: 'Failed')
    end
  end

  def query_reply
    conversation = Conversation.find_by(id: params[:conversation_id])
    bot_message = params[:result]
    key_phrases = ["I don't know", "I don't understand", 'No matched documents found', 'Internal server error']
    if key_phrases.any? { |phrase| bot_message.include?(phrase) }
      bot_message = Chatbot.find_by(id: params[:chatbot_id]).reply_on_no_relevant_result || I18n.t('chatbots.reply_on_no_relevant_result')
      MessageTemplates::Template::ChatbotReply.new(conversation: conversation).perform(bot_message, true)
    else
      MessageTemplates::Template::ChatbotReply.new(conversation: conversation).perform(bot_message, false)
    end
  end

  def links_crawled
    key = generate_key(params[:user_id])
    ::Redis::Alfred.setex(key, params[:result].to_json, 5.minutes)
  end

  private

  def generate_key(user_id)
    "crawl_links_cache_#{user_id}"
  end
end
