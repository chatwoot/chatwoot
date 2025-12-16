require 'administrate/base_dashboard'

class AccountAddressDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    street: Field::String,
    exterior_number: Field::String,
    interior_number: Field::String,
    neighborhood: Field::String,
    postal_code: Field::String,
    city: Field::String,
    state: Field::String,
    email: Field::String,
    phone: Field::String,
    webpage: Field::String,
    establishment_summary: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    street
    city
    state
    phone
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    street
    exterior_number
    interior_number
    neighborhood
    postal_code
    city
    state
    email
    phone
    webpage
    establishment_summary
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    account
    street
    exterior_number
    interior_number
    neighborhood
    postal_code
    city
    state
    email
    phone
    webpage
    establishment_summary
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(address)
    "#{address.street} #{address.exterior_number}, #{address.city}"
  end
end
