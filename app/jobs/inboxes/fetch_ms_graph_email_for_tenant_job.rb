require 'net/http'

class Inboxes::FetchMsGraphEmailForTenantJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    process_email_for_channel(channel)
  rescue EOFError => e
    Rails.logger.error e
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def should_fetch_email?(channel)
    channel.imap_enabled? && channel.microsoft? && !channel.reauthorization_required?
  end

  def process_email_for_channel(channel)
    # fetching email for microsoft provider
    fetch_mail_for_channel(channel)

    # clearing old failures like timeouts since the mail is now successfully processed
    channel.reauthorized!
  end

  def fetch_mail_for_channel(channel)
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token channel

    return unless access_token

    graph = graph_authenticate(access_token)

    process_mails(graph, channel)
  end

  def process_mails(graph, channel)
    response = graph.get_from_api('me/messages', {}, graph_query)

    unless response.is_a?(Net::HTTPSuccess)
      channel.authorization_error!
      return false
    end

    json_response = JSON.parse(response.body)
    json_response['value'].each do |message|
      inbound_mail = Mail.read_from_string retrieve_mail_mime(graph, message['id'])

      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def retrieve_mail_mime(graph, id)
    response = graph.get_from_api("me/messages/#{id}/$value")
    return unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def graph_authenticate(access_token)
    MicrosoftGraphApi.new(access_token)
  end

  def yesterday
    (Time.zone.today - 1).strftime('%FT%TZ')
  end

  def tomorrow
    (Time.zone.today + 1).strftime('%FT%TZ')
  end

  # Query to replicate the IMAP search used in Inboxes::FetchImapEmailsJob
  # Selects the top 1000 records within the given filter, as that is the maximum
  # page size for the API. Might need to look into paginating the requests later,
  # for inboxes that receive more than 1000 emails a day?
  #
  # 1. https://learn.microsoft.com/en-us/graph/api/user-list-messages
  # 2. https://learn.microsoft.com/en-us/graph/query-parameters
  def graph_query
    {
      '$filter': "receivedDateTime ge #{yesterday} and receivedDateTime le #{tomorrow}",
      '$top': '1000', '$select': 'id'
    }
  end

  def process_mail(inbound_mail, channel)
    Imap::ImapMailbox.new.process(inbound_mail, channel)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  # Making sure the access token is valid for microsoft provider
  def valid_access_token(channel)
    Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
  end
end
