class Imap::FetchEmailService < Imap::BaseFetchEmailService
  def fetch_emails
    fetch_mail_for_channel
  end

  private

  def authentication_type
    channel.imap_authentication || 'PLAIN'
  end

  def imap_password
    channel.imap_password
  end
end
