require 'securerandom'
require 'http'
class Api::V1::Widget::ChatbotController < ApplicationController
  # [POST] http://localhost:3000/api/v1/widget/store-to-db
  def store_to_db
    bot_name = params[:botName]
    account_id = params[:accountId]
    website_token = params[:website_token]
    inbox_id = params[:inbox_id]
    inbox_name = params[:inbox_name]
    last_trained_at = DateTime.now.strftime('%B %d, %Y at %I:%M %p')
    begin
      chatbot_inbox = Chatbot.find_by(inbox_id: inbox_id)
      if chatbot_inbox
        chatbot_inbox.update(inbox_id: nil)
        chatbot_inbox.update(inbox_name: 'No Inbox Connected')
        chatbot_inbox.update(website_token: nil)
      end
      if account_id
        # Create a new Chatbot record
        chatbot_id = SecureRandom.uuid
        chatbot = Chatbot.new(
          chatbot_name: bot_name,
          chatbot_id: chatbot_id,
          last_trained_at: last_trained_at,
          account_id: account_id,
          website_token: website_token,
          inbox_id: inbox_id,
          inbox_name: inbox_name,
          bot_status: true
        )
        if chatbot.save
          render json: { chatbot_id: chatbot.chatbot_id }, status: :created
        else
          render json: { error: 'Failed to store in db' }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Account ID is missing' }, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [post] http://localhost:3000/api/v1/widget/toggle-chatbot-status
  def toggle_chatbot_status
    conversation_id = params[:conversation_id]
    begin
      conversation = Conversation.find_by(id: conversation_id)
      if conversation
        # bot-icon status is toggled
        bot_icon_status = !conversation.bot_icon_status
        conversation.update(bot_icon_status: bot_icon_status)
        render json: { status: bot_icon_status }, status: :ok
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # def del
  #   Chatbot.delete_all
  #   render json: {message: "Chatbots deleted"}, status: :ok
  # end

  # [GET] http://localhost:3000/api/v1/widget/chatbot-status
  def chatbot_status
    conversation_id = params[:conversation_id]
    begin
      conversation = Conversation.find_by(id: conversation_id)
      render json: { status: nil }, status: :ok if conversation && conversation.is_bot_connected == false
      if conversation
        status = conversation.is_bot_connected
        render json: { status: status }, status: :ok
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [POST] http://localhost:3000/api/v1/widget/old-bot-train
  def old_bot_train
    chatbot_id = params[:chatbot_id]

    begin
      OldBotTrainWorker.perform_async(chatbot_id)
      render json: { message: 'Old bot training job enqueued successfully' }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [GET] http://localhost:3000/api/v1/widget/chatbot-with-account-id?account_id=123
  def fetch_chatbot_with_account_id
    account_id = params[:account_id]
    begin
      chatbots = Chatbot.where(account_id: account_id, bot_status: true).select(:chatbot_id, :chatbot_name, :last_trained_at)
      render json: chatbots.map { |chatbot|
                     { chatbot_id: chatbot.chatbot_id, chatbot_name: chatbot.chatbot_name, last_trained_at: chatbot.last_trained_at }
                   }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [DELETE] http://localhost:3000/api/v1/widget/chatbot-with-chatbot-id
  def delete_chatbot_with_chatbot_id
    chatbot_id = params[:chatbot_id]
    begin
      chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
      if chatbot
        chatbot.update(bot_status: false)
        chatbot.upadte(website_token: nil)
        chatbot.upadte(inbox_id: nil)
        chatbot.upadte(inbox_name: 'No Inbox Connected')
        render json: { message: 'Successfully deleted chatbot' }, status: :ok
      else
        render json: { error: 'Chatbot not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [GET] http://localhost:3000/api/v1/widget/chatbot-id-to-name
  def chatbot_id_to_name
    chatbot_id = params[:chatbot_id]
    begin
      chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
      name = ''
      id = nil
      if chatbot
        name = chatbot.inbox_name
        id = chatbot.inbox_id
      end
      render json: { name: name, id: id }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [POST] http://localhost:3000/api/v1/widget/create-chatbot-microservice
  def create_chatbot_microservice
    url = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot'
    data = params.to_unsafe_h

    begin
      response = HTTP.post(url, form: data)
      return JSON.parse(response.body) if response.code == 200 || response.code == 201

      { error: "Unexpected response code: #{response.code}" }
    rescue HTTP::Error => e
      # Handle HTTP errors
      { error: e.message }
    end
  end

  # [DELETE] http://localhost:3000/api/v1/widget/disconnect-chatbot
  def disconnect_chatbot
    chatbot_id = params[:chatbot_id]
    begin
      chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
      if chatbot
        chatbot.update(website_token: nil)
        chatbot.update(inbox_id: nil)
        chatbot.update(inbox_name: 'No Inbox Connected')
        render json: { message: 'Successfully disconnected chatbot', chatbot_id: chatbot.chatbot_id }, status: :ok
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [PUT] http://localhost:3000/api/v1/widget/update-bot-info
  def update_bot_info
    chatbot_id = params[:chatbot_id]
    new_bot_name = params[:new_bot_name]
    website_token = params[:website_token]
    inbox_id = params[:inbox_id]
    inbox_name = params[:inbox_name]
    begin
      if inbox_id != ''
        chatbot_inbox = Chatbot.find_by(inbox_id: inbox_id)
        if chatbot_inbox
          chatbot_inbox.update(inbox_id: nil)
          chatbot_inbox.update(inbox_name: 'No Inbox Connected')
          chatbot_inbox.update(website_token: nil)
        end
      end
      chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
      if chatbot
        chatbot.update(inbox_name: inbox_name) if inbox_name != ''
        chatbot.update(chatbot_name: new_bot_name) if new_bot_name != ''
        chatbot.update(website_token: website_token) if website_token != ''
        chatbot.update(inbox_id: inbox_id) if inbox_id != ''
        render json: { message: 'Successfully updated chatbot info' }, status: :ok
      else
        render json: { error: 'Chatbot not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end

# app/workers/old_bot_train_worker.rb
class OldBotTrainWorker
  include Sidekiq::Worker

  def perform(chatbot_id)
    chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
    raise 'Chatbot not found' unless chatbot

    chatbot.update(last_trained_at: DateTime.now.strftime('%B %d, %Y at %I:%M %p'))
  end
end