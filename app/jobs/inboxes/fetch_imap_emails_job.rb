require 'net/imap'

class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless should_fetch_email?(channel)

    process_mail_for_channel(channel)
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::IMAP::NoResponseError
    channel.authorization_error!
  rescue StandardError => e
    channel.authorization_error!
    Sentry.capture_exception(e)
  end

  private

  def should_fetch_email?(channel)
    channel.imap_enabled? && !channel.reauthorization_required?
  end

  def process_mail_for_channel(channel)
    # TODO: rather than setting this as default method for all mail objects, lets if can do new mail object
    # using Mail.retriever_method.new(params)
    Mail.defaults do
      retriever_method :imap, address: channel.imap_address,
                              port: channel.imap_port,
                              user_name: channel.imap_email,
                              password: channel.imap_password,
                              enable_ssl: channel.imap_enable_ssl
    end

    new_mails = false

    Mail.find(what: :last, count: 10, order: :desc).each do |inbound_mail|
      if inbound_mail.date.utc >= channel.imap_inbox_synced_at
        Imap::ImapMailbox.new.process(inbound_mail, channel)
        new_mails = true
      end
    end

    channel.update(imap_inbox_synced_at: Time.now.utc) if new_mails
  end
end
