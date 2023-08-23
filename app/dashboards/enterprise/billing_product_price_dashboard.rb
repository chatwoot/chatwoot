require 'administrate/base_dashboard'

class Enterprise::BillingProductPriceDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    billing_product: Field::BelongsTo.with_options(searchable: true, searchable_field: 'product_name', order: 'id DESC'),
    id: Field::Number,
    price_stripe_id: Field::String,
    active: Field::Boolean,
    stripe_nickname: Field::String,
    unit_amount: Field::Number,
    features: Field::Number,
    limits: Enterprise::AccountLimitsField, 
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    price_stripe_id
    active
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    price_stripe_id
    active
    stripe_nickname
    unit_amount
    features
    created_at
    updated_at
    limits
  ].freeze

  

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    billing_product
    price_stripe_id
    active
    stripe_nickname
    unit_amount
    features
    limits
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how billing product prices are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(billing_product_price)
    "Billing Product Price ##{billing_product_price.id} ##{billing_product_price.billing_product.product_name}"
  end

  def limits_display(resource)
    resource.limits.map { |key, value| "#{key}: #{value}" }.join(", ")
  end
end
