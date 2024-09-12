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

        payload = { id: id, urls: links, files: files, text: params[:text] }
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
    visited_links = Set.new
    # Crawl the links recursively
    links_map = crawl_links(url)
    links_with_char_count = links_map.map { |link, count| { link: link, char_count: count } }
    render json: { links_with_char_count: links_with_char_count }, status: :ok
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

  def crawl_links(url, visited_links = Set.new, links_map = {})
    return links_map if visited_links.include?(url)

    visited_links.add(url)

    begin
      html_content = URI.open(url).read
    rescue OpenURI::HTTPError => e
      puts "Failed to fetch #{url}: #{e.message}"
      return links_map
    rescue StandardError => e
      puts "An error occurred while processing #{url}: #{e.message}"
      return links_map
    end

    # Parse the HTML content
    doc = Nokogiri::HTML(html_content)

    # Extract visible text and calculate character count
    visible_text = doc.text.strip
    content_char_count = visible_text.length
    links_map[url] = content_char_count

    links = doc.css('a').map { |link| link['href'] }.compact
    links.map! { |link| URI.join(url, link).to_s }
    links.reject! { |link| URI.parse(link).fragment }
    links.select! { |link| link.start_with?(url) }

    links.each do |link|
      links_map.merge!(crawl_links(link, visited_links, links_map))
    end

    links_map
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
end
