class Integrations::Dyte::ProcessorService
  pattr_initialize [:account!, :conversation!]

  def create_a_meeting(agent)
    title = I18n.t('integration_apps.dyte.meeting_name', agent_name: agent.available_name)
    response = dyte_client.create_a_meeting(title)

    return response if response[:error].present?

    meeting = response
    message = create_a_dyte_integration_message(meeting, title, agent)
    message.push_event_data
  end

  def add_participant_to_meeting(meeting_id, user)
    dyte_client.add_participant_to_meeting(meeting_id, user.id, user.name, avatar_url(user))
  end

  private

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
    credentials = dyte_hook.settings
    @dyte_client ||= Dyte.new(credentials['organization_id'], credentials['api_key'])
  end
end
