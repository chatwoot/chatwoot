require 'administrate/base_dashboard'

class AddonDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String.with_options(searchable: true),
    description: Field::Text.with_options(truncate: 200),
    status: Field::Select.with_options(collection: %w[active inactive]),
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    package: Field::BelongsToSearch.with_options(class_name: 'Package', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    users_limit: Field::Number,
    channels_limit: Field::Number,
    contacts_limit: Field::Number,
    conversations_limit: Field::Number,
    campaign_messages_limit: Field::Number,
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
    name
    account
    package
    status
    starts_at
    ends_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    description
    status
    account
    package
    users_limit
    channels_limit
    contacts_limit
    conversations_limit
    campaign_messages_limit
    starts_at
    ends_at
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    description
    status
    account
    package
    users_limit
    channels_limit
    contacts_limit
    conversations_limit
    campaign_messages_limit
    starts_at
    ends_at
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  COLLECTION_FILTERS = {
    active: ->(resources) { resources.where(status: :active) },
    inactive: ->(resources) { resources.where(status: :inactive) }
  }.freeze

  # Overwrite this method to customize how add-ons are displayed
  # across all pages of the admin dashboard.
  def display_resource(addon)
    addon.name
  end
end
