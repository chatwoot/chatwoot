require 'net/imap'

class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless should_fetch_email?(channel)

    fetch_mail_for_channel(channel)
    # clearing old failures like timeouts since the mail is now successfully processed
    channel.reauthorized!
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::IMAP::NoResponseError, Errno::ECONNRESET, Errno::ENETUNREACH, Net::IMAP::ByeResponseError
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

  def process_mail(inbound_mail, channel)
    Imap::ImapMailbox.new.process(inbound_mail, channel)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end
end
