require 'administrate/base_dashboard'

class AccountPackageDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    package: Field::BelongsToSearch.with_options(class_name: 'Package', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    starts_at: Field::DateTime,
    ends_at: Field::DateTime,
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
    package
    starts_at
    ends_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    package
    starts_at
    ends_at
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  # `account` is rendered as a hidden field by the custom view but must stay
  # permitted so the assignment is scoped to the account being edited.
  FORM_ATTRIBUTES = %i[
    account
    package
    starts_at
    ends_at
  ].freeze

  # Overwrite this method to customize how account packages are displayed
  # across all pages of the admin dashboard.
  def display_resource(account_package)
    "AccountPackage ##{account_package.id} #{account_package.account&.name} - #{account_package.package&.name}"
  end
end
