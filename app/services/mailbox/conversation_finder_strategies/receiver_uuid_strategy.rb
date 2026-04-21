class Mailbox::ConversationFinderStrategies::ReceiverUuidStrategy < Mailbox::ConversationFinderStrategies::BaseStrategy
  # Pattern from ApplicationMailbox::REPLY_EMAIL_UUID_PATTERN
  UUID_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i

  def find
    uuid = extract_uuid_from_receivers
    return nil unless uuid

    Conversation.find_by(uuid: uuid)
  end

  private

  def extract_uuid_from_receivers
    mail_presenter = MailPresenter.new(mail)
    return nil if mail_presenter.mail_receiver.blank?

    mail_presenter.mail_receiver.each do |email|
      username = email.split('@').first
      match = username.match(UUID_PATTERN)
      return match[1] if match
    end

    nil
  end
end
