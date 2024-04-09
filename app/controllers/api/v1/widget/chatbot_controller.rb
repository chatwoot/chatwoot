require 'securerandom'
require 'http'

class Api::V1::Widget::ChatbotController < ApplicationController
  include ChatbotHelper
  # [POST] http://localhost:3000/api/v1/widget/store-to-db
  def store_to_db
    bot_name = params[:botName]
    account_id = params[:accountId]
    website_token = params[:website_token]
    inbox_id = params[:inbox_id]
    inbox_name = params[:inbox_name]
    last_trained_at = DateTime.now.strftime('%B %d, %Y at %I:%M %p')
    begin
      if account_id
        # Create a new Chatbot record
        chatbot_id = SecureRandom.uuid
        chatbot = Chatbot.new(
          chatbot_name: bot_name,
          chatbot_id: chatbot_id,
          last_trained_at: last_trained_at,
          account_id: account_id
        )
        if chatbot.save
          ChatbotHelper::CHATBOT_ID_TO_INBOX_NAME_MAPPING[chatbot_id] = inbox_name
          ChatbotHelper::WEBSITE_TOKEN_TO_CHATBOT_ID_MAPPING[website_token] = chatbot_id
          ChatbotHelper::INBOX_ID_TO_WEBSITE_TOKEN_MAPPING[inbox_id] = website_token
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
      # Check if the conversation_id exists in the mapping
      if ChatbotHelper::CONVERSATION_ID_TO_BOT_STATUS_MAPPING.key?(conversation_id)
        # Toggle the bot status for the given conversation_id
        ChatbotHelper.toggle_bot_status(conversation_id)
        # Get the updated status after toggling
        updated_status = ChatbotHelper::CONVERSATION_ID_TO_BOT_STATUS_MAPPING[conversation_id]
        render json: { status: updated_status }, status: :ok
      else
        ChatbotHelper::CONVERSATION_ID_TO_BOT_STATUS_MAPPING[conversation_id] = true
        render json: { status: true }, status: :ok
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [GET] http://localhost:3000/api/v1/widget/chatbot-status
  def chatbot_status
    conversation_id = params[:conversation_id]
    begin
      # Check if the conversation_id exists in the mapping
      if ChatbotHelper::CONVERSATION_ID_TO_BOT_STATUS_MAPPING.key?(conversation_id)
        # Get the status for the given conversation_id
        status = ChatbotHelper::CONVERSATION_ID_TO_BOT_STATUS_MAPPING[conversation_id]
        render json: { status: status }, status: :ok
      else
        ChatbotHelper::CONVERSATION_ID_TO_BOT_STATUS_MAPPING[conversation_id] = true
        render json: { status: true }, status: :ok
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

  # [POST] http://localhost:3000/api/v1/widget/change-bot-name
  def change_bot_name
    chatbot_id = params[:chatbot_id]
    new_bot_name = params[:new_bot_name]

    begin
      chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
      if chatbot
        chatbot.update(chatbot_name: new_bot_name)
        render json: { message: 'Successfully updated chatbot name' }, status: :ok
      else
        render json: { error: 'Chatbot not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # [GET] http://localhost:3000/api/v1/widget/chatbot-with-account-id?account_id=123
  def fetch_chatbot_with_account_id
    account_id = params[:account_id]
    begin
      chatbots = Chatbot.where(account_id: account_id).select(:chatbot_id, :chatbot_name, :last_trained_at)
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
        chatbot.destroy
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
      name = ChatbotHelper::CHATBOT_ID_TO_INBOX_NAME_MAPPING[chatbot_id]
      render json: { name: name }, status: :ok
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

  # [PUT] http://localhost:3000/api/v1/widget/update-bot-info
  def update_bot_info
    chatbot_id = params[:chatbot_id]
    new_bot_name = params[:new_bot_name]
    website_token = params[:website_token]
    inbox_id = params[:inbox_id]
    inbox_name = params[:inbox_name]
    ChatbotHelper::CHATBOT_ID_TO_INBOX_NAME_MAPPING[chatbot_id] = inbox_name if inbox_name != ''
    begin
      chatbot = Chatbot.find_by(chatbot_id: chatbot_id)
      if chatbot
        chatbot.update(chatbot_name: new_bot_name) if new_bot_name.present?
        ChatbotHelper::WEBSITE_TOKEN_TO_CHATBOT_ID_MAPPING[website_token] = chatbot_id
        ChatbotHelper::INBOX_ID_TO_WEBSITE_TOKEN_MAPPING[inbox_id] = website_token
        render json: { message: 'Successfully updated chatbot name' }, status: :ok
      else
        render json: { error: 'Chatbot not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # # cron job to sync map of ruby and python microservice daily at 2 am
  # def sync_maps_with_microservice
  #   url = ENV.fetch('MICROSERVICE_URL', nil) # Replace 'MICROSERVICE_URL' with the actual URL of your Python microservice
  #   data = {
  #     website_token_to_chatbot_id_mapping: WEBSITE_TOKEN_TO_CHATBOT_ID_MAPPING,
  #     inbox_id_to_website_token_mapping: INBOX_ID_TO_WEBSITE_TOKEN_MAPPING,
  #     conversation_id_to_bot_status_mapping: CONVERSATION_ID_TO_BOT_STATUS_MAPPING,
  #     chatbot_id_to_inbox_name_mapping: CHATBOT_ID_TO_INBOX_NAME_MAPPING
  #   }

  #   begin
  #     response = HTTP.post(url, json: data)
  #     if response.status.success?
  #       # Handle success
  #       render json: { message: 'Maps data synced with microservice successfully' }, status: :ok
  #     else
  #       # Handle failure
  #       render json: { error: 'Failed to sync maps data with microservice' }, status: :unprocessable_entity
  #     end
  #   rescue HTTP::Error => e
  #     # Handle exceptions
  #     render json: { error: e.message }, status: :unprocessable_entity
  #   end
  # end
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