require 'http'
class Api::V1::Accounts::ChatbotsController < Api::V1::Accounts::BaseController
  before_action :fetch_chatbot, only: [:show, :update]
  before_action :check_authorization, only: [:show, :update]

  def index
    @chatbots = Current.account.chatbots
  end

  def show
    head :not_found if @chatbot.nil?
  end

  def create_chatbot
    if is_website_inbox_occupied_by_another_chatbot(params)
      render json: { error: "Account already has a chatbot connected with #{params['inbox_name']} inbox" }, status: :unprocessable_entity
    else
      create_record_in_db(params)
      id = Chatbot.find_by(inbox_id: params[:inbox_id]).id
      if id.present?
        create_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/create'
        account_id = params['account_id']
        urls = params['urls'].split(',')
        payload = { id: id, account_id: account_id, urls: urls, account_char_limit: ENV.fetch('CHAR_LIMIT', 10000000) }
        begin
          response = HTTP.post(create_uri, form: payload)
        rescue HTTP::Error => e
          { error: e.message }
        end
      end
    end
  end

  def update
    @chatbot = Chatbot.find_by(id: params[:id])
    return unless @chatbot

    status = if params[:chatbotStatus]
               'Enabled'
             else
               'Disabled'
             end
    @chatbot.update!(name: params[:chatbotName], reply_on_no_relevant_result: params[:chatbotReplyOnNoRelevantResult], status: status)
  end

  def destroy_chatbot
    chatbot = Chatbot.find_by(id: params[:id])
    return unless chatbot

    chatbot.destroy
    ChatbotItem.find_by(chatbot_id: params[:id]).destroy
    delete_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/delete'
    payload = { id: chatbot.id, account_id: chatbot.account_id }
    response = HTTP.delete(delete_uri, form: payload)
  end

  def retrain_chatbot
    @chatbot = Chatbot.find_by(id: params[:chatbotId])
    return unless @chatbot

    urls = params['urls'].split(',')
    ChatbotItem.find_by(chatbot_id: params[:chatbotId]).update(urls: urls)
    retrain_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/retrain'
    urls = params['urls'].split(',')
    payload = { id: params[:chatbotId], account_id: params[:accountId], urls: urls }
    begin
      response = HTTP.post(retrain_uri, form: payload)
      @chatbot.update(status: 'Retraining') if response.code == 200
    rescue HTTP::Error => e
      { error: e.message }
    end
  end

  private

  def create_record_in_db(params)
    @chatbot = Chatbot.new(
      name: SecureRandom.alphanumeric(10),
      reply_on_no_relevant_result: I18n.t('chatbots.reply_on_no_relevant_result'),
      last_trained_at: DateTime.now.strftime('%B %d, %Y at %I:%M %p'),
      account_id: params['accountId'],
      website_token: params['website_token'],
      inbox_id: params['inbox_id'],
      inbox_name: params['inbox_name'],
      status: 'Creating'
    )
    render json: { error: @chatbot.errors.messages }, status: :unprocessable_entity and return unless @chatbot.valid?

    @chatbot.save!
    urls = params['urls'].split(',')
    @chatbot_data = ChatbotItem.new(
      chatbot_id: @chatbot.id,
      files: params['files'],
      text: params['text'],
      urls: urls
    )
    render json: { error: @chatbot_data.errors.messages }, status: :unprocessable_entity and return unless @chatbot_data.valid?

    @chatbot_data.save!
  end

  def is_website_inbox_occupied_by_another_chatbot(params)
    Chatbot.exists?(inbox_id: params['inbox_id'])
  end

  def fetch_chatbot
    @chatbot = Current.account.chatbots.find_by(id: params[:id])
  end

  def check_authorization
    authorize(@chatbot) if @chatbot.present?
  end
end
