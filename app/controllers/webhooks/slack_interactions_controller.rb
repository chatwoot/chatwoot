class Webhooks::SlackInteractionsController < ActionController::API
  # Slack sends the button's action_id, which maps to what we do with the held back reply.
  ACTIONS = { 'slack_takeover_send' => 'takeover', 'slack_send_only' => 'send_only' }.freeze

  before_action :verify_signature!

  def process_payload
    return head :ok if action.blank?

    # Answering immediately keeps us inside Slack's 3 second budget. Clearing the prompt and
    # creating the reply both happen in the job.
    SlackPendingReplyJob.perform_later(reference, action, payload['response_url'])
    head :ok
  end

  private

  def verify_signature!
    head :unauthorized unless Integrations::Slack::SignatureVerifier.valid?(request)
  end

  def payload
    @payload ||= JSON.parse(params[:payload])
  end

  def selected_action
    payload['actions'].first
  end

  def action
    ACTIONS[selected_action['action_id']]
  end

  # The button value points back at the Slack message the agent typed.
  def reference
    JSON.parse(selected_action['value']).slice('channel', 'thread_ts', 'ts')
  end
end
