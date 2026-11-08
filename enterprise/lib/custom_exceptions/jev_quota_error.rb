class CustomExceptions::JevQuotaError < StandardError
  attr_reader :code, :retry_after

  def initialize(code, retry_after:)
    @code = code
    @retry_after = retry_after
    super(code)
  end
end
