module Enterprise::Captain::JevClient
  def call(body:, &)
    usage = ConversationMonitors::Usage.new(@account_id)
    usage.reserve!(body.bytesize)
    data = super
    input_tokens = data.dig('usage', 'input_tokens')
    # Keep the conservative reservation when the provider does not report usable token usage.
    reconcile_usage(usage, body.bytesize, input_tokens) if input_tokens.is_a?(Integer) && input_tokens >= 0
    data
  rescue Captain::JevClient::HTTPError => e
    # Provider rejections release the daily budget, but retain the monthly call credit.
    reconcile_usage(usage, body.bytesize, 0) if e.status.between?(400, 499)
    raise
  end

  private

  def reconcile_usage(usage, reserved, used)
    usage.reconcile!(reserved, used)
  rescue Redis::BaseError, ConnectionPool::TimeoutError => e
    # Preserve the result after an uncertain adjustment rather than repeating a paid request.
    Rails.logger.warn("Jev token reconciliation failed: account_id=#{@account_id} error=#{e.class.name}")
  end
end
