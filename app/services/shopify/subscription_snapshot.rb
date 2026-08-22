class Shopify::SubscriptionSnapshot
  ENTITLED_STATES = %w[active trialing cancelled].freeze
  STATES = (ENTITLED_STATES + %w[expired missing]).freeze

  attr_reader :attributes

  def self.from_partner_response(data, verified_at: Time.current)
    active_subscription = data['activeSubscription']
    latest_event = data.dig('events', 'edges', 0, 'node')

    new(build_attributes(active_subscription, latest_event, verified_at))
  end

  def self.from_h(attributes)
    new(attributes)
  end

  def initialize(attributes)
    @attributes = attributes.deep_stringify_keys
    raise ArgumentError, "Unknown Shopify subscription state: #{state}" unless STATES.include?(state)
  end

  def state
    attributes.fetch('state')
  end

  def plan_handles
    attributes.fetch('plan_handles')
  end

  def entitled?
    ENTITLED_STATES.include?(state)
  end

  def to_h
    attributes.deep_dup
  end

  class << self
    private

    def build_attributes(active_subscription, latest_event, verified_at)
      subscription_items = Array(active_subscription&.fetch('items', nil))
      primary_item = subscription_items.one? ? subscription_items.first : nil

      {
        'state' => subscription_state(active_subscription, latest_event, verified_at),
        'plan_handles' => subscription_items.pluck('handle').compact,
        'plan_name' => primary_item&.fetch('description', nil),
        'amount' => primary_item&.dig('price', 'amount'),
        'currency' => primary_item&.dig('price', 'currency'),
        'billing_period' => active_subscription&.fetch('billingPeriod', nil),
        'trial_ends_at' => active_subscription&.fetch('trialEndsAt', nil),
        'current_period_start' => active_subscription&.dig('currentBillingCycle', 'startTime'),
        'current_period_end' => active_subscription&.dig('currentBillingCycle', 'endTime'),
        'cancel_at_period_end' => active_subscription&.fetch('cancelAtEndOfCycle', false) || false,
        'shop_id' => active_subscription&.dig('shop', 'id'),
        'shop_domain' => active_subscription&.dig('shop', 'myshopifyDomain'),
        'latest_event' => normalize_event(latest_event),
        'verified_at' => verified_at.iso8601(6)
      }
    end

    def subscription_state(active_subscription, latest_event, verified_at)
      if active_subscription.present?
        return 'cancelled' if active_subscription['cancelAtEndOfCycle'] == true
        return 'trialing' if active_trial?(active_subscription, verified_at)

        return 'active'
      end

      %w[CANCELED FROZEN].include?(latest_event&.fetch('state', nil)) ? 'expired' : 'missing'
    end

    def active_trial?(active_subscription, verified_at)
      trial_ends_at = active_subscription['trialEndsAt']
      trial_ends_at.present? && Time.iso8601(trial_ends_at) > verified_at
    end

    def normalize_event(latest_event)
      return if latest_event.blank?

      latest_event.slice('state', 'cancelEffectiveOn', 'occurredAt').transform_keys(&:underscore)
    end
  end
end
