class Integrations::Shopee::Error < StandardError
  attr_reader :response

  def initialize(message, response = nil)
    @response = response
    super(message)
  end
end
