class Email::FromBuilder < Email::BaseBuilder
  pattr_initialize [:inbox!, :message!]

  def build
    return sender_name(account_support_email) unless inbox.email?

    from_email = case email_channel_type
                 when :standard_imap_smtp,
                      :google_oauth,
                      :microsoft_oauth,
                      :forwarding_own_smtp
                   channel.email
                 when :imap_chatwoot_smtp,
                      :forwarding_chatwoot_smtp
                   channel.verified_for_sending ? channel.email : account_support_email
                 else
                   account_support_email
                 end

    sender_name(from_email)
  end

  private

  def email_channel_type
    return :google_oauth if channel.google?
    return :microsoft_oauth if channel.microsoft?
    return :standard_imap_smtp if imap_and_smtp_enabled?
    return :imap_chatwoot_smtp if imap_enabled_without_smtp?
    return :forwarding_own_smtp if forwarding_with_own_smtp?
    return :forwarding_chatwoot_smtp if forwarding_without_smtp?

    :unknown
  end

  def imap_and_smtp_enabled?
    channel.imap_enabled && channel.smtp_enabled
  end

  def imap_enabled_without_smtp?
    channel.imap_enabled && !channel.smtp_enabled
  end

  def forwarding_with_own_smtp?
    !channel.imap_enabled && channel.smtp_enabled
  end

  def forwarding_without_smtp?
    !channel.imap_enabled && !channel.smtp_enabled
  end
end
