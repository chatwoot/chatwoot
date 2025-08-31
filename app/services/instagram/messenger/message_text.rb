class Instagram::Messenger::MessageText < Instagram::BaseMessageText
  private

  def ensure_contact(ig_scope_id)
    Rails.logger.info "[Instagram::Messenger] Fetching user profile - Source:#{ig_scope_id}"

    result = fetch_instagram_user(ig_scope_id)
    if result.present?
      Rails.logger.info "[Instagram::Messenger] User profile fetched successfully - Source:#{ig_scope_id}"
      find_or_create_contact(result)
    else
      Rails.logger.warn "[Instagram::Messenger] User profile fetch returned empty - Source:#{ig_scope_id}"
    end
  end

  def fetch_instagram_user(ig_scope_id)
    k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?

    Rails.logger.debug { "[Instagram::Messenger] Koala API request for source:#{ig_scope_id}" }

    k.get_object(ig_scope_id) || {}
  rescue Koala::Facebook::AuthenticationError => e
    handle_authentication_error(e)
    {}
  rescue StandardError, Koala::Facebook::ClientError => e
    handle_client_error(e)
    {}
  end

  def handle_authentication_error(error)
    Rails.logger.error "[Instagram::Messenger] Authentication error - Account:#{@inbox.account_id}, Inbox:#{@inbox.id}"
    @inbox.channel.authorization_error!
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def handle_client_error(error)
    # Handle error code 230: User consent is required to access user profile
    # This typically occurs when the connected Instagram account attempts to send a message to a user
    # who has never messaged this Instagram account before.
    # We can safely ignore this error as per Facebook documentation.
    if error.message.include?('230')
      Rails.logger.warn "[Instagram::Messenger] User consent required (230) - ignoring: #{error}"
      return
    end

    Rails.logger.error("[Instagram::Messenger] Client error - account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.error("[Instagram::Messenger] Error details: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def create_message
    return unless @contact_inbox

    Rails.logger.info "[Instagram::Messenger] Delegating to MessageBuilder - ContactInbox:#{@contact_inbox.id}"
    Messages::Instagram::Messenger::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
