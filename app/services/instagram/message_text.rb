class Instagram::MessageText < Instagram::BaseMessageText
  attr_reader :messaging

  def ensure_contact(ig_scope_id)
    result = Instagram::FetchInstagramUserService.new(@inbox.id, ig_scope_id).perform
    find_or_create_contact(result) if result.present?
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
