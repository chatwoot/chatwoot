class Imap::FetchEmailService < Imap::BaseFetchEmailService
  def fetch_emails
    fetch_mail_for_channel
  end

  private

  def authentication_type
    'PLAIN'
  end

  def imap_password
    channel.imap_password
  end
end
