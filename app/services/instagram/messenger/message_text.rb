class Instagram::Messenger::MessageText < Instagram::BaseMessageText
  private

  def ensure_contact(ig_scope_id)
    result = fetch_instagram_user(ig_scope_id)
    find_or_create_contact(result) if result.present?
  end

  def fetch_instagram_user(ig_scope_id)
    k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
    k.get_object(ig_scope_id) || {}
  rescue Koala::Facebook::AuthenticationError => e
    handle_authentication_error(e)
    {}
  rescue StandardError, Koala::Facebook::ClientError => e
    handle_client_error(e)
    {}
  end

  def handle_authentication_error(error)
    @inbox.channel.authorization_error!
    Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def handle_client_error(error)
    Rails.logger.warn("[FacebookUserFetchClientError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[FacebookUserFetchClientError]: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::Messenger::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
