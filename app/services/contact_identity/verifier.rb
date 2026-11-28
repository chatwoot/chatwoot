class ContactIdentity::Verifier
  STRATEGIES = [
    ContactIdentity::Strategies::HmacStrategy
  ].freeze

  def initialize(channel:, identifier:, params:)
    @strategies = STRATEGIES.map do |strategy_class|
      strategy_class.new(channel: channel, identifier: identifier, params: params)
    end
  end

  def perform
    strategy = @strategies.find(&:presented?)
    return ContactIdentity::Proof.none if strategy.nil?

    strategy.verify
  end
end
