class EmailChannelFinder
  def initialize(email_object)
    @email_object = email_object
  end

  def perform
    channel = nil
    recipient_mails = @email_object.to.to_a + @email_object.cc.to_a
    recipient_mails.each do |email|
      mail_id, domain = email.split('@')
      original_mail_address = mail_id.split('+')[0]
      channel = Channel::Email.where('lower(email) ~* ? OR lower(forward_to_email) ~* ?',
                                     "#{original_mail_address}\+\.*\@#{domain}",
                                     "#{original_mail_address}\+\.*\@#{domain}").last
      break if channel.present?
    end
    channel
  end
end
