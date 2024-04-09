require 'administrate/base_dashboard'

class CouponCodeDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account_id: Field::String.with_options(searchable: true), # Allow searching by account id
    account_name: Field::String.with_options(searchable: true), # Allow searching by account name
    code: Field::String,
    partner: Field::String,
    status: Field::String.with_options(searchable: true), # Allow searching by status
    redeemed_at: Field::DateTime.with_options(format: '%d %b %Y %H:%M:%S'), # Time shown on super_admin dashboard is in UTC
    expiry_date: Field::DateTime.with_options(format: '%d %b %Y'),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  COLLECTION_ATTRIBUTES = %i[
    id
    account_id
    account_name
    code
    partner
    status
    redeemed_at
    expiry_date
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account_id
    account_name
    code
    partner
    status
    redeemed_at
    expiry_date
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  FORM_ATTRIBUTES = %i[
    status
    expiry_date
  ].freeze

  # COLLECTION_FILTERS
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how coupon codes are displayed
  # across all pages of the admin dashboard.
  def display_resource(coupon_code)
    "Coupon Code ##{coupon_code.id}"
  end
end
