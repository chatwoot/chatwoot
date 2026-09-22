class CustomExceptions::MonitorEvaluationError < StandardError
  attr_reader :code, :retry_after

  def initialize(code, retry_after: nil)
    @code = code
    @retry_after = retry_after
    super(code)
  end

  def retryable?
    %w[provider_busy provider_unavailable invalid_response rate_limit budget_limit monthly_limit].include?(code)
  end
end
