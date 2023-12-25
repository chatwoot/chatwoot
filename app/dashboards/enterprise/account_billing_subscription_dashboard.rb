require 'administrate/base_dashboard'

class Enterprise::AccountBillingSubscriptionDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES

  # a hash that describes the type of each of the model's fields.

  # Each different type represents an Administrate::Field object,

  # which determines how the attribute is displayed

  # on pages throughout the dashboard.

  ATTRIBUTE_TYPES = {
    account: Field::BelongsTo.with_options(searchable: true, searchable_field: 'name', order: 'id DESC'),
    id: Field::Number,
    stripe_customer_id: Field::String,
    stripe_subscription_id: Field::String,
    stripe_price_id: Field::String,
    stripe_product_id: Field::String,
    plan_name: Field::String,
    status: Field::String,
    current_period_end: Field::DateTime,
    subscription_status: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime

  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    account
    plan_name
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.

  SHOW_PAGE_ATTRIBUTES = %i[
    account
    id
    stripe_customer_id
    stripe_subscription_id
    stripe_price_id
    stripe_product_id
    plan_name
    status
    current_period_end
    subscription_status
    created_at
    updated_at

  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.

  FORM_ATTRIBUTES = %i[
    stripe_customer_id
    stripe_subscription_id
    stripe_price_id
    stripe_product_id
    plan_name
    subscription_status
    current_period_end
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze

  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how account billing subscriptions are displayed
  # across all pages of the admin dashboard.
  def display_resource(account_billing_subscription)
    "Account Billing Subscription ##{account_billing_subscription.id}"
  end
end
