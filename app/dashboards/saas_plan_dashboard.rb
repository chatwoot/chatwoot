require 'administrate/base_dashboard'

class SaasPlanDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    stripe_product_id: Field::String,
    stripe_price_id: Field::String,
    price_cents: Field::Number,
    interval: Field::Select.with_options(collection: [%w[Monthly month], %w[Yearly year]]),
    agent_limit: Field::Number,
    inbox_limit: Field::Number,
    ai_tokens_monthly: Field::Number,
    features: Field::String.with_options(searchable: false),
    active: Field::Boolean,
    subscriptions: Field::HasMany.with_options(class_name: 'Saas::Subscription'),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    price_cents
    interval
    agent_limit
    active
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    stripe_product_id
    stripe_price_id
    price_cents
    interval
    agent_limit
    inbox_limit
    ai_tokens_monthly
    features
    active
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    stripe_product_id
    stripe_price_id
    price_cents
    interval
    agent_limit
    inbox_limit
    ai_tokens_monthly
    active
  ].freeze

  def display_resource(plan)
    "#{plan.name} ($#{(plan.price_cents / 100.0).round(2)}/#{plan.interval})"
  end
end
