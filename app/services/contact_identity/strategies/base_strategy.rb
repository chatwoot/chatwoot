class ContactIdentity::Strategies::BaseStrategy
  attr_reader :channel, :identifier, :params

  def initialize(channel:, identifier:, params:)
    @channel = channel
    @identifier = identifier
    @params = params
  end

  # Returns true when the request carries this kind of proof
  # Subclasses must implement this method
  def presented?
    raise NotImplementedError, "#{self.class} must implement #presented?"
  end

  # Returns a ContactIdentity::Proof
  # Subclasses must implement this method
  def verify
    raise NotImplementedError, "#{self.class} must implement #verify"
  end
end
