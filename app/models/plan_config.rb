# PORO that loads plan definitions from config/plans.yml.
# Not an ActiveRecord model — plans are code, not data.
#
# Console usage:
#   PlanConfig.all                          # => [PlanConfig, ...]
#   PlanConfig.find("pro_monthly")          # => PlanConfig
#   PlanConfig.for_price("price_xxx")       # => PlanConfig (lookup by Stripe price ID)
#   plan.ai_response_limit                  # => 25000
#   plan.feature_enabled?(:api_access)      # => true
#   plan.pro?                               # => true
#
class PlanConfig
  PLANS = YAML.safe_load(
    ERB.new(Rails.root.join('config/plans.yml').read).result,
    permitted_classes: [], aliases: true
  ).fetch('plans').freeze

  attr_reader :key, :name, :tier, :interval, :amount_kd,
              :stripe_price_id, :limits, :features

  def initialize(key, data)
    @key = key
    @name = data['name']
    @tier = data['tier']
    @interval = data['interval']
    @amount_kd = data['amount_kd']
    @stripe_price_id = data['stripe_price_id']
    @limits = (data['limits'] || {}).symbolize_keys
    @features = (data['features'] || {}).symbolize_keys
  end

  class << self
    def find(plan_key)
      data = PLANS[plan_key]
      raise ArgumentError, "Unknown plan: #{plan_key}" unless data

      new(plan_key, data)
    end

    def for_price(stripe_price_id)
      key, data = PLANS.find { |_k, v| v['stripe_price_id'] == stripe_price_id }
      return nil unless key

      new(key, data)
    end

    def all
      PLANS.map { |key, data| new(key, data) }
    end
  end

  def ai_response_limit  = limits[:ai_responses_per_month]
  def kb_document_limit  = limits[:knowledge_base_documents]

  def feature_enabled?(feature)
    features.fetch(feature, false)
  end

  def basic? = tier == 'basic'
  def pro?   = tier == 'pro'

  def to_h
    { key: key, name: name, tier: tier, interval: interval,
      amount_kd: amount_kd, limits: limits, features: features }
  end
end
