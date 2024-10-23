require 'http'
class Api::V1::Accounts::ChatbotsController < Api::V1::Accounts::BaseController
  before_action :fetch_chatbot, only: [:show, :update]
  before_action :check_authorization, only: [:show, :update]
  before_action :check_microservice_status, only: [:create_chatbot, :destroy_chatbot, :retrain_chatbot]

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
        parsed_links = JSON.parse(params[:urls])
        links = parsed_links.map { |url_obj| url_obj['link'] }

        files = []
        if params[:files].present?
          params[:files].each do |_, file_data|
            file = file_data['file']
            tempfile = file.tempfile.open
            files << HTTP::FormData::File.new(tempfile, filename: file.original_filename)
          end
        end

        payload = { id: id, urls: links, files: files, text: params[:text], inbox_id: params[:inbox_id] }
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
    @chatbot.update!(
      name: params[:chatbotName],
      reply_on_no_relevant_result: params[:chatbotReplyOnNoRelevantResult],
      reply_on_connect_with_team: params[:chatbotReplyOnConnectWithTeam],
      status: status
    )
  end

  def destroy_chatbot
    chatbot = Chatbot.find_by(id: params[:id])
    return unless chatbot

    conversations = Conversation.where("chatbot_attributes ->> 'id' = ?", params[:id].to_s)
    conversations.find_each do |conversation|
      conversation.update(chatbot_attributes: {})
    end
    chatbot.destroy!
    begin
      delete_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/delete'
      payload = { id: chatbot.id }
      response = HTTP.delete(delete_uri, form: payload)
    rescue Errno::ECONNREFUSED => e
      puts "Connection refused: #{e.message}"
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
    end
  end

  def retrain_chatbot
    @chatbot = Chatbot.find_by(id: params[:chatbotId])
    return unless @chatbot

    @chatbot.update(urls: JSON.parse(params[:urls]), text: params[:text])
    attach_files(params[:files]) if params[:files].present?

    retrain_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/retrain'
    parsed_links = JSON.parse(params[:urls])
    links = parsed_links.map { |url_obj| url_obj['link'] }

    files = []
    if params[:files].present?
      params[:files].each do |_, file_data|
        file = file_data['file']
        tempfile = file.tempfile.open
        files << HTTP::FormData::File.new(tempfile, filename: file.original_filename)
      end
    end

    saved_attachment = get_attachments(params[:chatbotId])
    if saved_attachment.present?
      saved_files = saved_attachment.map do |attachment|
        file_data = URI.open(attachment[:file_url])
        tempfile = Tempfile.new([attachment[:filename], File.extname(attachment[:filename])])
        tempfile.binmode
        tempfile.write(file_data.read)
        tempfile.rewind

        HTTP::FormData::File.new(tempfile, filename: attachment[:filename])
      end

      files.concat(saved_files)
    end

    payload = { id: params[:chatbotId], urls: links, files: files, text: params[:text] }
    begin
      response = HTTP.post(retrain_uri, form: payload)
      @chatbot.update(status: 'Retraining') if response.code == 200
    rescue HTTP::Error => e
      { error: e.message }
    end
  end

  def fetch_links
    url = params[:url]
    begin
      scrape_uri = ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/scrape'
      @user = User.find_by!(pubsub_token: current_user.pubsub_token)
      payload = { url: url, user_id: @user.id }
      response = HTTP.post(scrape_uri, form: payload)
    rescue HTTP::Error => e
      { error: e.message }
    end
    render json: { message: 'Crawling started' }, status: :ok
  end

  def check_crawling_status
    links_with_char_count = retrieve_data_from_redis
    if links_with_char_count
      render json: { links_with_char_count: links_with_char_count }, status: :ok
    else
      render json: { error: 'Data not found' }, status: :ok
    end
  end

  def saved_data
    chatbot_data = Chatbot.find_by(id: params[:id])
    if chatbot_data
      files = chatbot_data.file_base_data if chatbot_data.files.any?
      render json: { urls: chatbot_data[:urls], files: files, text: chatbot_data[:text] }, status: :ok
    else
      render json: { error: 'Data not found' }, status: :not_found
    end
  end

  def process_pdf
    if params[:file].present?
      text = ''
      File.open(params[:file].tempfile, 'rb') do |io|
        reader = PDF::Reader.new(io)
        reader.pages.each do |page|
          text << page.text
        end
      end
      char_count = text.length.to_i
      render json: { char_count: char_count }, status: :ok
    else
      render json: { error: 'No file uploaded' }, status: :bad_request
    end
  end

  def destroy_attachment
    @chatbot = Chatbot.find(params[:chatbot_id])
    attachment = @chatbot.files.find_by(id: params[:attachment_id])
    if attachment
      attachment.purge
      render json: { message: 'File deleted successfully.', filename: params[:filename] }, status: :ok
    else
      render json: { error: 'File not found.' }, status: :not_found
    end
  end

  private

  def check_microservice_status
    return if is_microservice_alive

    Rails.logger.info 'Microservice is not alive.'
    render json: { error: 'Internal server error' }, status: :unprocessable_entity
  end

  def is_microservice_alive
    microservice_url = URI.parse(ENV.fetch('MICROSERVICE_URL', nil))
    begin
      response = Net::HTTP.get_response(microservice_url)
      return true if response.is_a?(Net::HTTPSuccess)

      false
    rescue Errno::ECONNREFUSED => e
      false
    rescue StandardError => e
      false
    end
  end

  def create_record_in_db(params)
    @chatbot = Chatbot.new(
      name: SecureRandom.alphanumeric(10),
      reply_on_no_relevant_result: I18n.t('chatbots.reply_on_no_relevant_result'),
      reply_on_connect_with_team: I18n.t('chatbots.reply_on_connect_with_team'),
      last_trained_at: DateTime.now.strftime('%B %d, %Y at %I:%M %p'),
      account_id: params['accountId'],
      website_token: params['website_token'],
      inbox_id: params['inbox_id'],
      inbox_name: params['inbox_name'],
      status: 'Creating',
      text: params['text'],
      urls: JSON.parse(params['urls'])
    )

    attach_files(params[:files]) if params[:files].present?
    @chatbot.save!
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

  def attach_files(files)
    files.each do |_, file_data|
      next unless file_data['file'] && file_data['char_count']

      file = file_data['file']
      char_count = file_data['char_count']

      @chatbot.files.attach(
        io: file,
        filename: file.original_filename,
        metadata: { char_count: char_count.to_i }
      )
    end
  end

  def get_attachments(chatbot_id)
    chatbot = Chatbot.find(chatbot_id)
    chatbot.file_base_data
  end

  def retrieve_data_from_redis
    key = generate_key(@user.id)
    data = Redis::Alfred.get(key)
    return unless data

    parsed_data = JSON.parse(data)
    Redis::Alfred.delete(key)
    parsed_data
  end

  def generate_key(user_id)
    "crawl_links_cache_#{user_id}"
  end
end
