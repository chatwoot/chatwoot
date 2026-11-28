class ContactIdentity::Verifier
  # The token strategy stays out of this list until the callers compare the identifier a token carries.
  # Today they trust the identifier param, which a token does not cover.
  DEFAULT_STRATEGIES = [
    ContactIdentity::Strategies::HmacStrategy
  ].freeze

  def initialize(channel:, identifier:, params:, strategies: DEFAULT_STRATEGIES)
    @strategies = strategies.map do |strategy_class|
      strategy_class.new(channel: channel, identifier: identifier, params: params)
    end
  end

  def perform
    presented_strategies = @strategies.select(&:presented?)
    return ContactIdentity::Proof.none if presented_strategies.empty?
    return ContactIdentity::Proof.invalid if presented_strategies.many?

    presented_strategies.first.verify
  end
end
