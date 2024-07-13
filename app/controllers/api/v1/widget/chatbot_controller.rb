require 'http'
class Api::V1::Widget::ChatbotController < ApplicationController
  def create
    if is_website_inbox_occupied_by_another_chatbot(params)
      render json: { error: "Account already has a chatbot connected with #{params["inbox_name"]} inbox" }, status: :unprocessable_entity
    else
      create_record_in_db(params)
      id = Chatbot.find_by(inbox_id: params[:inbox_id]).id
      if id.present?
        create_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/create'
        urls = params["bot_urls"].split(',')
        payload = {id: id, urls: urls}
        begin
          response = HTTP.post(create_uri, form: payload)
          return JSON.parse(response.body) if response.code == 200 || response.code == 201
      
          { error: "Unexpected response code: #{response.code}" }
        rescue HTTP::Error => e
          { error: e.message }
        end
      end
    end
  end

  def receive_result
    chatbot = Chatbot.find_by(id: params[:id])
    if chatbot
      chatbot.update(bot_status: 'Enabled')
    end
  end
  
  def get
    @chatbots = Chatbot.where(account_id: params[:account_id])
    render 'api/v1/accounts/chatbots/show', format: :json, locals: { resource: @chatbots }
  end

  def delete
    chatbot = Chatbot.find_by(id: params[:id])
    if chatbot
      delete_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/delete'
      # chatbot.destroy
      payload = {id: chatbot.id}
      response = HTTP.delete(delete_uri, form: payload)
    end
  end
  # def toggle_chatbot_status
  #   conversation_id = params[:conversation_id]
  #   begin
  #     conversation = Conversation.find_by(id: conversation_id)
  #     if conversation
  #       # bot-icon status is toggled
  #       bot_icon_status = !conversation.bot_icon_status
  #       conversation.update(bot_icon_status: bot_icon_status)
  #       render json: { status: bot_icon_status }, status: :ok
  #     end
  #   rescue StandardError => e
  #     render json: { error: e.message }, status: :unprocessable_entity
  #   end
  # end


  # [GET] http://localhost:3000/api/v1/widget/chatbot-status
  # def chatbot_status
  #   conversation_id = params[:conversation_id]
  #   begin
  #     conversation = Conversation.find_by(id: conversation_id)
  #     render json: { status: nil }, status: :ok if conversation && conversation.is_bot_connected == false
  #     if conversation
  #       status = conversation.is_bot_connected
  #       render json: { status: status }, status: :ok
  #     end
  #   rescue StandardError => e
  #     render json: { error: e.message }, status: :unprocessable_entity
  #   end
  # end

  # [POST] http://localhost:3000/api/v1/widget/old-bot-train
  # def old_bot_train
  #   chatbot_id = params[:chatbot_id]

  #   begin
  #     OldBotTrainWorker.perform_async(chatbot_id)
  #     render json: { message: 'Old bot training job enqueued successfully' }, status: :ok
  #   rescue StandardError => e
  #     render json: { error: e.message }, status: :unprocessable_entity
  #   end
  # end


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

  private

  def create_record_in_db(params)
    begin
      chatbot = Chatbot.new(
        chatbot_name: SecureRandom.alphanumeric(10),
        last_trained_at: DateTime.now.strftime('%B %d, %Y at %I:%M %p'),
        account_id: params["accountId"],
        website_token: params["website_token"],
        inbox_id:  params["inbox_id"],
        inbox_name: params["inbox_name"],
        bot_status: "Creating",
      )
      chatbot.save!
      bot_urls = params["bot_urls"].split(',')
      chatbot_data = ChatbotItem.new(
        chatbot_id: chatbot.id,
        bot_files: params["bot_files"],
        bot_text: params["bot_text"],
        bot_urls: bot_urls,
      )
      chatbot_data.save!
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def is_website_inbox_occupied_by_another_chatbot(params)
    Chatbot.exists?(inbox_id: params["inbox_id"])
  end
end

