class Instagram::Messenger::MessageText < Instagram::BaseMessageText
  include HTTParty

  private

  # rubocop:disable Metrics/AbcSize
  def ensure_contact(ig_scope_id)
    begin
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
      result = k.get_object(ig_scope_id) || {}
    rescue Koala::Facebook::AuthenticationError => e
      @inbox.channel.authorization_error!
      Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    rescue StandardError, Koala::Facebook::ClientError => e
      Rails.logger.warn("[FacebookUserFetchClientError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
      Rails.logger.warn("[FacebookUserFetchClientError]: #{e.message}")
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end

    find_or_create_contact(result) if defined?(result) && result.present?
  end
  # rubocop:enable Metrics/AbcSize

  def create_message
    return unless @contact_inbox

    Messages::Instagram::Messenger::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
