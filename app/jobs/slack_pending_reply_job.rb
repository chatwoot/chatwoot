class SlackPendingReplyJob < ApplicationJob
  queue_as :medium

  def perform(reference, action, response_url = nil)
    dismiss_prompt(response_url)

    hook = Integrations::Hook.find_by(reference_id: reference['channel'])
    return if hook.blank?

    reply = fetch_reply(hook, reference)
    return if reply.blank?

    Integrations::Slack::IncomingMessageBuilder.new(
      ActiveSupport::HashWithIndifferentAccess.new(
        type: 'event_callback', confirmed_action: action, event: reply.merge('channel' => reference['channel'])
      )
    ).perform
  end

  private

  # An ephemeral message has no timestamp to delete by, so the only way to clear it is
  # posting back to the response_url Slack handed us with the click.
  def dismiss_prompt(response_url)
    return if response_url.blank?

    HTTParty.post(response_url, headers: { 'Content-Type' => 'application/json' }, body: { delete_original: true }.to_json)
  end

  # Slack holds the reply the agent typed, so it is read back on confirmation instead of
  # being copied anywhere. A reply deleted before the agent answers simply stops here.
  def fetch_reply(hook, reference)
    replies = Slack::Web::Client.new(token: hook.access_token).conversations_replies(
      channel: reference['channel'], ts: reference['thread_ts'],
      latest: reference['ts'], oldest: reference['ts'], inclusive: true, limit: 1
    )
    replies.messages&.find { |message| message['ts'] == reference['ts'] }&.to_h
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error "[Slack] could not read back the held back reply (hook=#{hook.id}): #{e.message}"
    nil
  end
end
