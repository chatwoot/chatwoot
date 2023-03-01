class EmailChannelFinder
  include EmailHelper

  def initialize(email_object)
    @email_object = email_object
  end

  def perform
    channel = nil
    recipient_mails = @email_object.to.to_a + @email_object.cc.to_a
    recipient_mails.each do |email|
      normalized_email = normalize_email_with_plus_addressing(email)
      channel = Channel::Email.find_by('lower(email) = ? OR lower(forward_to_email) = ?', normalized_email, normalized_email)
      break if channel.present?
    end
    channel
  end
end
