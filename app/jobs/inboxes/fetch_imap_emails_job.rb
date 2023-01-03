require 'net/imap'

class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless should_fetch_email?(channel)

    if channel.ms_oauth_token_available?
      fetch_mail_for_ms_oauth_channel(channel)
    else
      fetch_mail_for_channel(channel)
    end
    # clearing old failures like timeouts since the mail is now successfully processed
    channel.reauthorized!
  rescue *ExceptionList::IMAP_EXCEPTIONS
    channel.authorization_error!
  rescue EOFError => e
    Rails.logger.error e
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def should_fetch_email?(channel)
    channel.imap_enabled? && !channel.reauthorization_required?
  end

  def fetch_mail_for_channel(channel)
    # TODO: rather than setting this as default method for all mail objects, lets if can do new mail object
    # using Mail.retriever_method.new(params)
    Mail.defaults do
      retriever_method :imap, address: channel.imap_address,
                              port: channel.imap_port,
                              user_name: channel.imap_login,
                              password: channel.imap_password,
                              enable_ssl: channel.imap_enable_ssl
    end

    Mail.find(what: :last, count: 10, order: :asc).each do |inbound_mail|
      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def fetch_mail_for_ms_oauth_channel(channel)
    imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    imap.authenticate('XOAUTH2', channel.email, channel.ms_oauth_token)
    imap.select('INBOX')
    imap.search(['ALL']).each do |message_id|
      inbound_mail = Mail.read_from_string imap.fetch(message_id, 'RFC822')[0].attr['RFC822']

    access_token = valid_imap_ms_oauth_token channel

    return unless access_token

    auth = 'Bearer ' + access_token
    all_mails = HTTParty.get("https://graph.microsoft.com/v1.0/me/mailfolders/inbox/messages", :headers => { "Authorization" => auth })['value']

    all_mails.each do |mail|
      inbound_mail = Mail.read_from_string mail
      next if channel.inbox.messages.find_by(source_id: inbound_mail['id'].value).present?

      process_mail(inbound_mail, channel)
    end

    # imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    # imap.authenticate('XOAUTH2', 'tejaswinichile@chatwoot.onmicrosoft.com', "Bearer eyJ0eXAiOiJKV1QiLCJub25jZSI6ImNhTG15M19HX2lvLUxjYmFWME1SLUZlYnJCQ3FYbWpkRkRlNlAtZmxaX1EiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyIsImtpZCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyJ9.eyJhdWQiOiJodHRwczovL2dyYXBoLm1pY3Jvc29mdC5jb20iLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9hMWUzYjU0Zi04NDc0LTQ1MjItYmUyNC04ODIxOTdlODgzMDYvIiwiaWF0IjoxNjcyNzUwOTEzLCJuYmYiOjE2NzI3NTA5MTMsImV4cCI6MTY3Mjc1NTYxNywiYWNjdCI6MCwiYWNyIjoiMSIsImFpbyI6IkFWUUFxLzhUQUFBQVR4S05wK0VQYTUwTC9YK2poM2IycVhqbGZtVndoeXpjb2hXVkd0dmVycFd1Yi9ydXJnb3NIb2dmdXBuQzV5QXhZZGQ0WnlvR0Qwa2RrbGJNSldodWVzcXY3MDNlQlZCeThYc3hSRjBLSXYwPSIsImFtciI6WyJwd2QiLCJtZmEiXSwiYXBwX2Rpc3BsYXluYW1lIjoic3Vic2NyaWJlZC1jaGF0d29vdCIsImFwcGlkIjoiZDk2OTUxNjUtNDA0Mi00NWI1LTk5YWYtYWFmOGQwOWM5OGFlIiwiYXBwaWRhY3IiOiIxIiwiZmFtaWx5X25hbWUiOiJjaGlsZSIsImdpdmVuX25hbWUiOiJ0ZWphc3dpbmkiLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiI0OS4yNDguODguNDMiLCJuYW1lIjoidGVqYXN3aW5pIGNoaWxlIiwib2lkIjoiZmExMzQ5ZDMtODAwMi00MmI4LWI2YWEtZDdhMWMxYzJmMDk3IiwicGxhdGYiOiI1IiwicHVpZCI6IjEwMDMyMDAyNUY0QjU2RjciLCJyaCI6IjAuQVZZQVQ3WGpvWFNFSWtXLUpJZ2hsLWlEQmdNQUFBQUFBQUFBd0FBQUFBQUFBQUNmQUtnLiIsInNjcCI6ImVtYWlsIElNQVAuQWNjZXNzQXNVc2VyLkFsbCBNYWlsLlJlYWQgb3BlbmlkIHByb2ZpbGUgU01UUC5TZW5kIFVzZXIuUmVhZCIsInNpZ25pbl9zdGF0ZSI6WyJrbXNpIl0sInN1YiI6IkNTTGNmN2xrWWJBZmdVS3k3WDZDX2FQUGw1SmoyZlhCMEdWRWN5alZSbDgiLCJ0ZW5hbnRfcmVnaW9uX3Njb3BlIjoiQVMiLCJ0aWQiOiJhMWUzYjU0Zi04NDc0LTQ1MjItYmUyNC04ODIxOTdlODgzMDYiLCJ1bmlxdWVfbmFtZSI6InRlamFzd2luaWNoaWxlQGNoYXR3b290Lm9ubWljcm9zb2Z0LmNvbSIsInVwbiI6InRlamFzd2luaWNoaWxlQGNoYXR3b290Lm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6InlpdlZjYTRMVVVHZE02YWdZdm5pQVEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjYyZTkwMzk0LTY5ZjUtNDIzNy05MTkwLTAxMjE3NzE0NWUxMCIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfc3QiOnsic3ViIjoiU0dyUWNxTTc3bVQ4TFdDLTJQT1p5eHY0LS0ycjRLR2FDYjNhc0h2ZDV1QSJ9LCJ4bXNfdGNkdCI6MTY3MjExNzA1OH0.Jy4qdXGqQYpw9Ejx29uc4Q_Q1mB1jMYEHRVDUqe2oteGznAgTvjrtINKB9ny1_YdHs5uMt2ZpTGRXBLEwJTkBDaUResKVQtTPqPLsB25_80NEHuJJvZJrqJaA6b7RfwTCGhd6gjtvqnH0FkmMO6iirDnqoaGlrvFhgz2y-yZbG2pl6emwdFBo6IlFhOuQyqecRI5LlW9nnq7jK5p6OFtQ8q0OIShwB_AXY5fSIJX-Wtm6yV-82dDm2-sX5Lb0PYQsY72ZKly29yK6c_K8ouDt7JBRZY1oxNBr_pa6FyTYTygAk3CxOoUZeXIeMU7pus0w0B7JjKVaQob5d_BsuC4rg")
    # imap.select('INBOX')
    # imap.search(['ALL']).each do |message_id|
    #   inbound_mail =  Mail.read_from_string imap.fetch(message_id,'RFC822')[0].attr['RFC822']

    #   next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

    #   process_mail(inbound_mail, channel)
    # end
  end

  def process_mail(inbound_mail, channel)
    Imap::ImapMailbox.new.process(inbound_mail, channel)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  def valid_imap_ms_oauth_token(channel)
    Channels::RefreshMsOauthTokenJob.new.access_token(channel, channel.ms_oauth_token_hash.with_indifferent_access)
  end
end
