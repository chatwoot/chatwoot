class Webhooks::MoengageController < ActionController::API
  def process_payload
    hook = find_hook
    return head :not_found unless hook
    return head :forbidden unless hook.account.active?

    # Store webhook immediately for durability and visibility
    event_log = create_pending_log(hook)

    # Process asynchronously
    Webhooks::MoengageEventsJob.perform_later(event_log.id)

    head :ok
  end

  private

  def find_hook
    Integrations::Hook.where(app_id: 'moengage', status: :enabled)
                      .where("settings->>'webhook_token' = ?", params[:webhook_token])
                      .first
  end

  def create_pending_log(hook)
    payload = params.to_unsafe_hash.except(:webhook_token, :controller, :action)

    MoengageWebhookEventLog.create!(
      account: hook.account,
      hook: hook,
      event_name: payload[:event_name] || payload[:event_type],
      status: :pending,
      payload: payload
    )
  end
end
