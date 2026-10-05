# Works out who a Slack reply came from, preferring the matching Chatwoot agent so replies
# are attributed to a real profile, and falling back to the Slack profile when there is none.
class Integrations::Slack::SenderResolver
  pattr_initialize [:slack_client!, :account!, :slack_user_id!]

  # Returns [chatwoot_user, sender_name, sender_avatar_url]. Either the user is set, or the
  # name and avatar are, depending on whether the Slack profile matches an agent.
  def perform
    return [nil, nil, nil] if slack_user_id.blank?

    slack_user = slack_client.users_info(user: slack_user_id)[:user]
    chatwoot_user = account.users.from_email(slack_user[:profile][:email])
    return [chatwoot_user, nil, nil] if chatwoot_user

    [nil, display_name(slack_user), slack_user.dig(:profile, :image_192).presence]
  rescue Slack::Web::Api::Errors::MissingScope
    raise
  rescue StandardError
    [nil, nil, nil]
  end

  private

  def display_name(slack_user)
    slack_user.dig(:profile, :display_name).presence || slack_user[:real_name].presence || slack_user[:name]
  end
end
