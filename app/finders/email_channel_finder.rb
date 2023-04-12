class EmailChannelFinder
  include EmailHelper

  def initialize(email_object)
    @email_object = email_object
  end

  def perform
    channel = nil

    recipient_mails.each do |email|
      normalized_email = normalize_email_with_plus_addressing(email)
      channel = Channel::Email.find_by('lower(email) = ? OR lower(forward_to_email) = ?', normalized_email, normalized_email)

      break if channel.present?
    end
    channel
  end

  def recipient_mails
    recipient_addresses = @email_object.to.to_a + @email_object.cc.to_a + @email_object.bcc.to_a + [@email_object['X-Original-To'].try(:value)]
    recipient_addresses.flatten.compact
  end
end
