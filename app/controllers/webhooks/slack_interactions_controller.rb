class Webhooks::SlackInteractionsController < ActionController::API
  # Slack sends back the action_id of the element that was clicked, which we set as
  # "<interaction>.<action>". Supporting a new interaction means adding its job here. The job
  # receives the action, the element's value and the response_url.
  INTERACTIONS = { 'takeover' => SlackPendingReplyJob }.freeze

  before_action :verify_signature!

  def process_payload
    interaction, action = selected_action['action_id'].split('.', 2)
    job = INTERACTIONS[interaction]
    return head :ok if job.blank?

    job.perform_later(action, selected_action['value'], payload['response_url'])
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
end
