require 'administrate/base_dashboard'

class AccountAddonDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    addon: Field::BelongsToSearch.with_options(class_name: 'Addon', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    starts_at: Field::DateTime,
    ends_at: Field::DateTime,
    duration_type: Field::String,
    duration_months: Field::Number,
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
    account
    addon
    starts_at
    ends_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    addon
    starts_at
    ends_at
    duration_type
    duration_months
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  # `account` is rendered as a hidden field by the custom view but must stay
  # permitted so the activation is scoped to the account being edited.
  FORM_ATTRIBUTES = %i[
    account
    addon
    starts_at
    ends_at
    duration_type
    duration_months
  ].freeze

  # Overwrite this method to customize how account add-ons are displayed
  # across all pages of the admin dashboard.
  def display_resource(account_addon)
    "AccountAddon ##{account_addon.id} #{account_addon.account&.name} - #{account_addon.addon&.name}"
  end
end
