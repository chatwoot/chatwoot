class Integrations::Dyte::ProcessorService
  pattr_initialize [:account!, :conversation!]

  def create_a_meeting(agent)
    return missing_realtimekit_credentials_response if realtimekit_credentials_missing?

    title = I18n.t('integration_apps.dyte.meeting_name', agent_name: agent.available_name)
    response = dyte_client.create_a_meeting(title)

    return response if response[:error].present?

    meeting = response
    message = create_a_dyte_integration_message(meeting, title, agent)
    message.push_event_data
  end

  def add_participant_to_meeting(meeting_id, user, message = nil)
    return missing_realtimekit_credentials_response if realtimekit_credentials_missing?

    client_id = realtimekit_client_id(user)
    participant_id = realtimekit_participant_id(message, client_id)
    response = participant_token_response(meeting_id, participant_id)
    return response if response[:error].blank?

    response = dyte_client.add_participant_to_meeting(meeting_id, client_id, user.name, avatar_url(user))
    return store_participant_id_and_return(message, client_id, response) if response[:error].blank?

    existing_participant_token_response(meeting_id, client_id, message) || response
  end

  private

  def realtimekit_client_id(user)
    "#{user.class.name}:#{user.id}"
  end

  def store_participant_id_and_return(message, client_id, response)
    update_realtimekit_participant_id(message, client_id, response['id']) if response['id'].present?
    response
  end

  def create_a_dyte_integration_message(meeting, title, agent)
    @conversation.messages.create!(
      {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :outgoing,
        content_type: :integrations,
        content: title,
        content_attributes: {
          type: 'dyte',
          data: {
            meeting_id: meeting['id']
          }
        },
        sender: agent
      }
    )
  end

  def avatar_url(user)
    return user.avatar_url if user.avatar_url.present?

    "#{ENV.fetch('FRONTEND_URL', nil)}/integrations/slack/user.png"
  end

  def dyte_hook
    @dyte_hook ||= account.hooks.find_by!(app_id: 'dyte')
  end

  def dyte_client
    @dyte_client ||= Dyte.new(*realtimekit_credentials)
  end

  def participant_token_response(meeting_id, participant_id)
    return { error: :participant_id_missing } if participant_id.blank?

    dyte_client.refresh_participant_token(meeting_id, participant_id)
  end

  def existing_participant_token_response(meeting_id, client_id, message)
    participant_id = existing_realtimekit_participant_id(meeting_id, client_id)
    return if participant_id.blank?

    response = dyte_client.refresh_participant_token(meeting_id, participant_id)
    update_realtimekit_participant_id(message, client_id, participant_id) if response[:error].blank?
    response
  end

  def existing_realtimekit_participant_id(meeting_id, client_id)
    participants = dyte_client.fetch_participants(meeting_id)
    return if participants.blank? || participants.is_a?(Hash)

    participants.find { |participant| participant['custom_participant_id'].to_s == client_id.to_s }&.dig('id')
  end

  def realtimekit_participant_id(message, client_id)
    integration_message_data(message).dig(:participants, client_id.to_s)
  end

  def update_realtimekit_participant_id(message, client_id, participant_id)
    return if message.blank?

    attributes = message.content_attributes.with_indifferent_access
    data = (attributes[:data] || {}).with_indifferent_access
    participants = (data[:participants] || {}).with_indifferent_access
    participants[client_id.to_s] = participant_id
    data[:participants] = participants
    attributes[:data] = data
    message.update_columns(content_attributes: attributes.deep_stringify_keys, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  rescue StandardError => e
    Rails.logger.warn("[dyte] Failed to store RealtimeKit participant ID for message #{message.id}: #{e.class}: #{e.message}")
  end

  def integration_message_data(message)
    return {} if message.blank?

    (message.content_attributes.with_indifferent_access[:data] || {}).with_indifferent_access
  end

  def realtimekit_credentials
    credentials = dyte_hook.settings.with_indifferent_access
    [credentials[:account_id], credentials[:app_id], credentials[:api_token]]
  end

  def realtimekit_credentials_missing?
    realtimekit_credentials.any?(&:blank?)
  end

  def missing_realtimekit_credentials_response
    { error: I18n.t('errors.dyte.realtimekit_credentials_required') }
  end
end
