class Webhooks::MoengageEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:webhook_token]

    hook = find_hook(params[:webhook_token])

    if hook_is_inactive?(hook)
      log_inactive_hook(hook, params)
      return
    end

    process_webhook(hook, params)
  end

  private

  def find_hook(webhook_token)
    Integrations::Hook.where(app_id: 'moengage', status: :enabled)
                      .where("settings->>'webhook_token' = ?", webhook_token)
                      .first
  end

  def hook_is_inactive?(hook)
    return true if hook.blank?
    return true unless hook.account.active?

    false
  end

  def log_inactive_hook(hook, params)
    message = if hook&.id
                "Account #{hook.account.id} is not active for hook #{hook.id}"
              else
                "Hook not found for webhook_token: #{params[:webhook_token]}"
              end
    Rails.logger.warn("MoEngage event discarded: #{message}")
  end

  def process_webhook(hook, params)
    payload = params.except(:webhook_token, :controller, :action)

    Integrations::Moengage::WebhookProcessorService.new(
      hook: hook,
      payload: payload
    ).perform
  end
end
