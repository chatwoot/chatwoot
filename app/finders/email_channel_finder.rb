class EmailChannelFinder
  include EmailHelper

  def initialize(email_object)
    @email_object = email_object
  end

  def perform
    channel_from_primary_recipients || channel_from_bcc_recipients
  end

  private

  def channel_from_primary_recipients
    primary_recipient_emails.each do |email|
      channel = channel_from_email(email)
      return channel if channel.present?
    end

    nil
  end

  def channel_from_bcc_recipients
    bcc_recipient_emails.each do |email|
      channel = channel_from_email(email)

      # Skip if BCC processing is disabled for this account
      next if channel && !allow_bcc_processing?(channel.account_id)

      return channel if channel.present?
    end

    nil
  end

  def primary_recipient_emails
    (@email_object.to.to_a + @email_object.cc.to_a + [@email_object['X-Original-To'].try(:value)]).flatten.compact
  end

  def bcc_recipient_emails
    @email_object.bcc.to_a.flatten.compact
  end

  def channel_from_email(email)
    normalized_email = normalize_email_with_plus_addressing(email)
    Channel::Email.find_by('lower(email) = ? OR lower(forward_to_email) = ?', normalized_email, normalized_email)
  end

  def bcc_processing_skipped_accounts
    config_value = GlobalConfigService.load('SKIP_INCOMING_BCC_PROCESSING', '')
    return [] if config_value.blank?

    config_value.split(',').map(&:to_i)
  end

  def allow_bcc_processing?(account_id)
    bcc_processing_skipped_accounts.exclude?(account_id)
  end
end
