require 'administrate/base_dashboard'

class AccountDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.

  enterprise_attribute_types = ChatwootApp.enterprise? ? { limits: Enterprise::AccountLimitsField } : {}
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    users: CountField,
    conversations: CountField,
    locale: Field::Select.with_options(collection: LANGUAGES_CONFIG.map { |_x, y| y[:iso_639_1_code] }),
    account_users: Field::HasMany
  }.merge(enterprise_attribute_types).freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    locale
    users
    conversations
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  enterprise_show_page_attributes = ChatwootApp.enterprise? ? %i[limits] : []
  SHOW_PAGE_ATTRIBUTES = (%i[
    id
    name
    created_at
    updated_at
    locale
    conversations
    account_users
  ] + enterprise_show_page_attributes).freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  enterprise_form_attributes = ChatwootApp.enterprise? ? %i[limits] : []
  FORM_ATTRIBUTES = (%i[
    name
    locale
  ] + enterprise_form_attributes).freeze

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

  # Overwrite this method to customize how accounts are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(account)
    "##{account.id} #{account.name}"
  end

  def permitted_attributes
    super + [limits: {}]
  end
end
