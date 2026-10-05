# Captain keeps answering while a conversation is pending, so a reply typed in Slack would
# land alongside the bot's own. This holds the reply back until the agent says what they meant.
class Integrations::Slack::ConversationTakeover
  pattr_initialize [:conversation!, :params!, :slack_client!]

  # Gated on the signing secret because it is the one thing an admin sets while wiring up
  # interactivity. Without it the interactions endpoint rejects every click, so prompting
  # would strand the reply with no way to send it. Installs that have not set it up keep
  # the old behaviour of replying straight through.
  def confirmation_required?
    return false if Integrations::Slack::SignatureVerifier.signing_secret.blank?

    conversation.pending? && params[:confirmed_action].blank?
  end

  def confirmed?
    params[:confirmed_action] == 'takeover'
  end

  def request_confirmation
    slack_client.chat_postEphemeral(
      channel: params[:event][:channel],
      user: params[:event][:user],
      thread_ts: params[:event][:thread_ts],
      text: I18n.t('slack.takeover.prompt'),
      blocks: prompt_blocks
    )
  end

  # The agent is only assigned when their Slack profile resolves to a Chatwoot user,
  # the handoff still has to happen either way.
  def perform(agent)
    return unless conversation.pending?

    conversation.bot_handoff!
    conversation.update!(assignee: agent) if agent.is_a?(User)
  end

  private

  def prompt_blocks
    [
      { 'type' => 'section', 'text' => { 'type' => 'mrkdwn', 'text' => I18n.t('slack.takeover.prompt') } },
      {
        'type' => 'actions',
        'elements' => [
          prompt_button(I18n.t('slack.takeover.take_over'), 'slack_takeover_send').merge('style' => 'primary'),
          prompt_button(I18n.t('slack.takeover.send_only'), 'slack_send_only')
        ]
      }
    ]
  end

  def prompt_button(label, action_id)
    {
      'type' => 'button',
      'text' => { 'type' => 'plain_text', 'text' => label, 'emoji' => true },
      'value' => reply_reference,
      'action_id' => action_id
    }
  end

  # The buttons carry a pointer back to the Slack message rather than a copy of it,
  # so the reply is read from Slack when the agent answers.
  def reply_reference
    { channel: params[:event][:channel], thread_ts: params[:event][:thread_ts], ts: params[:event][:ts] }.to_json
  end
end
