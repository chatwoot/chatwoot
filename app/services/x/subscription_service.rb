class X::SubscriptionService
  pattr_initialize [:channel!]

  def subscribe
    webhook_id = ensure_webhook_exists
    return false unless webhook_id

    Rails.logger.info "Subscribing X user #{channel.profile_id} to activity events (webhook #{webhook_id})"

    success = subscribe_account_activity(webhook_id)
    success &= create_xaa_subscription('chat.received', webhook_id)
    success &= create_xaa_subscription('chat.sent', webhook_id)
    success
  rescue StandardError => e
    Rails.logger.error "X subscription failed for channel #{channel.id}: #{e.message}"
    false
  end

  def unsubscribe
    webhook_id = GlobalConfigService.load('X_WEBHOOK_ID', nil)
    unsubscribe_account_activity(webhook_id) if webhook_id.present?

    subscriptions = list_xaa_subscriptions
    subscriptions.each do |sub|
      delete_xaa_subscription(sub['subscription_id'])
    end
    true
  rescue StandardError => e
    Rails.logger.warn "X unsubscription failed for channel #{channel.id}: #{e.message}"
    true
  end

  private

  def subscribe_account_activity(webhook_id)
    response = HTTParty.post(
      "https://api.x.com/2/account_activity/webhooks/#{webhook_id}/subscriptions/all",
      headers: auth_headers
    )

    if [200, 201, 204].include?(response.code)
      Rails.logger.info "Account Activity subscription created for user #{channel.profile_id} (webhook #{webhook_id})"
      true
    elsif response.code == 409 || (response.code == 400 && response.body&.include?('DuplicateSubscription'))
      Rails.logger.info "Account Activity subscription already exists for user #{channel.profile_id}"
      true
    else
      error_msg = extract_error_message(response)
      Rails.logger.error "Account Activity subscription failed (#{response.code}): #{error_msg}"
      false
    end
  end

  def unsubscribe_account_activity(webhook_id)
    response = HTTParty.delete(
      "https://api.x.com/2/account_activity/webhooks/#{webhook_id}/subscriptions/#{channel.profile_id}/all",
      headers: auth_headers
    )

    if [200, 204].include?(response.code)
      Rails.logger.info "Account Activity subscription removed for user #{channel.profile_id}"
    else
      Rails.logger.warn "Failed to remove Account Activity subscription (#{response.code})"
    end
  end

  def create_xaa_subscription(event_type, webhook_id)
    response = HTTParty.post(
      'https://api.x.com/2/activity/subscriptions',
      headers: auth_headers,
      body: {
        event_type: event_type,
        filter: { user_id: channel.profile_id },
        webhook_id: webhook_id,
        tag: "chatwoot_#{channel.id}"
      }.to_json
    )

    if [200, 201].include?(response.code)
      Rails.logger.info "XAA subscribed to #{event_type} for user #{channel.profile_id}"
      true
    elsif response.code == 400 && response.body&.include?('DuplicateSubscription')
      Rails.logger.info "XAA subscription already exists for #{event_type}, skipping"
      true
    else
      error_msg = extract_error_message(response)
      Rails.logger.error "XAA failed to subscribe to #{event_type} (#{response.code}): #{error_msg}"
      false
    end
  end

  def list_xaa_subscriptions
    response = HTTParty.get(
      'https://api.x.com/2/activity/subscriptions',
      headers: auth_headers
    )

    return [] unless response.code == 200

    data = response.parsed_response['data'] || []
    data.select { |sub| sub.dig('filter', 'user_id') == channel.profile_id }
  end

  def delete_xaa_subscription(subscription_id)
    response = HTTParty.delete(
      "https://api.x.com/2/activity/subscriptions/#{subscription_id}",
      headers: auth_headers
    )

    if [200, 204].include?(response.code)
      Rails.logger.info "Deleted XAA subscription #{subscription_id}"
    else
      Rails.logger.warn "Failed to delete XAA subscription #{subscription_id} (#{response.code})"
    end
  end

  def auth_headers
    {
      'Authorization' => "Bearer #{channel.bearer_token}",
      'Content-Type' => 'application/json'
    }
  end

  def ensure_webhook_exists
    X::WebhookSetupService.ensure_webhook_registered
  end

  def extract_error_message(response)
    if response.parsed_response.is_a?(Hash)
      response.parsed_response.dig('errors', 0, 'message') ||
        response.parsed_response['error'] ||
        response.body
    else
      response.body
    end
  end
end
