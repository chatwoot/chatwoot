class Integrations::Slack::IncomingMessageBuilder
  include SlackMessageCreation
  attr_reader :params

  SUPPORTED_EVENT_TYPES = %w[event_callback url_verification].freeze
  SUPPORTED_EVENTS = %w[message link_shared].freeze
  SUPPORTED_MESSAGE_TYPES = %w[rich_text].freeze

  def initialize(params)
    @params = params
  end

  def perform
    return unless valid_event?

    if hook_verification?
      verify_hook
    elsif create_message?
      create_message
    elsif link_shared?
      create_link_shared_message
    end
  end

  private

  def valid_event?
    supported_event_type? && supported_event? && should_process_event?
  end

  def supported_event_type?
    SUPPORTED_EVENT_TYPES.include?(params[:type])
  end

  # Discard all the subtype of a message event
  # We are only considering the actual message sent by a Slack user
  # Any reactions or messages sent by the bot will be ignored.
  # https://api.slack.com/events/message#subtypes
  def should_process_event?
    return true if params[:type] != 'event_callback'

    params[:event][:user].present? && valid_event_subtype?
  end

  def valid_event_subtype?
    params[:event][:subtype].blank? || params[:event][:subtype] == 'file_share'
  end

  def supported_event?
    hook_verification? || SUPPORTED_EVENTS.include?(params[:event][:type])
  end

  def supported_message?
    if message.present?
      SUPPORTED_MESSAGE_TYPES.include?(message[:type]) && !attached_file_message?
    else
      params[:event][:files].present? && !attached_file_message?
    end
  end

  def hook_verification?
    params[:type] == 'url_verification'
  end

  def thread_timestamp_available?
    params[:event][:thread_ts].present?
  end

  def create_message?
    thread_timestamp_available? && supported_message? && integration_hook
  end

  def link_shared?
    params[:event][:type] == 'link_shared'
  end

  def create_link_shared_message
    url = params[:event][:links][0][:url]
    conversation_id_regex = %r{/conversations/(\d+)}
    match_data = url.match(conversation_id_regex)
    return unless match_data

    conversation_id = match_data[1] # The first capturing group contains the ID
    conversation = Conversation.find_by(display_id: conversation_id)
    return unless conversation

    user_name = conversation.contact&.name.presence || '---'
    email = conversation.contact&.email.presence || '---'
    phone_number = conversation.contact&.phone_number.presence || '---'
    company_name = conversation.contact&.additional_attributes&.dig('company_name').presence || '---'

    unfurls = { url => { 'blocks' => [{
      'type': 'section',
      'fields': [
        {
          'type': 'mrkdwn',
          'text': "*Name:*\n#{user_name}"
        },
        {
          'type': 'mrkdwn',
          'text': "*Email:*\n#{email}"
        },
        {
          'type': 'mrkdwn',
          'text': "*Phone:*\n#{phone_number}"
        },
        {
          'type': 'mrkdwn',
          'text': "*Company:*\n#{company_name}"
        }
      ]
    }, {

      'type': 'actions',
      'elements': [
        {
          'type': 'button',
          'text': {
            'type': 'plain_text',
            'text': 'Open conversation',
            'emoji': true
          },
          'url': url,
          'action_id': 'button-action'
        }
      ]
    }] } }
    Integrations::Slack::SendOnSlackService.new(message: nil, hook: integration_hook).link_unfurl(
      unfurl_id: params[:event][:unfurl_id],
      source: params[:event][:source],
      unfurls: JSON.generate(unfurls)
    )
  end

  def message
    params[:event][:blocks]&.first
  end

  def verify_hook
    {
      challenge: params[:challenge]
    }
  end

  def integration_hook
    @integration_hook ||= Integrations::Hook.find_by(reference_id: params[:event][:channel])
  end

  def conversation
    @conversation ||= Conversation.where(identifier: params[:event][:thread_ts]).first
  end

  def sender
    user_email = slack_client.users_info(user: params[:event][:user])[:user][:profile][:email]
    conversation.account.users.find_by(email: user_email)
  end

  def private_note?
    params[:event][:text].strip.downcase.starts_with?('note:', 'private:')
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: @integration_hook.access_token)
  end

  # Ignoring the changes added here https://github.com/chatwoot/chatwoot/blob/5b5a6d89c0cf7f3148a1439d6fcd847784a79b94/lib/integrations/slack/send_on_slack_service.rb#L69
  # This make sure 'Attached File!' comment is not visible on CW dashboard.
  # This is showing because of https://github.com/chatwoot/chatwoot/pull/4494/commits/07a1c0da1e522d76e37b5f0cecdb4613389ab9b6 change.
  # As now we consider the postback message with event[:files]
  def attached_file_message?
    params[:event][:text] == 'Attached File!'
  end
end
