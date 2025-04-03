class Messages::Instagram::MessageBuilder < Messages::Instagram::BaseMessageBuilder
  include HTTParty

  base_uri "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"

  def initialize(messaging, inbox, outgoing_echo: false)
    super(messaging, inbox, outgoing_echo: outgoing_echo)
  end

  private

  def get_story_object_from_source_id(source_id)
    url = "#{self.class.base_uri}/#{source_id}?fields=story,from&access_token=#{@inbox.channel.access_token}"
    response = HTTParty.get(url)

    Rails.logger.info("Instagram Story Response: #{response.body}")

    return JSON.parse(response.body).with_indifferent_access if response.success?

    handle_error_response(response)
    {}
  rescue StandardError => e
    handle_standard_error(e)
    {}
  end

  def handle_error_response(response)
    return unless response.code == 404

    @message.attachments.destroy_all
    @message.update(content: I18n.t('conversations.messages.instagram_deleted_story_content'))
  end

  def handle_standard_error(error)
    if error.response&.unauthorized?
      @inbox.channel.authorization_error!
      raise
    end
    Rails.logger.error("Instagram Story Error: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end
end
