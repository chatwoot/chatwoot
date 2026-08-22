require 'administrate/base_dashboard'

class AccountDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.

  ATTRIBUTE_TYPES = {
    id: Field::Number.with_options(searchable: true),
    name: Field::String.with_options(searchable: true),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    users: CountField,
    conversations: CountField,
    locale: Field::Select.with_options(collection: LANGUAGES_CONFIG.map { |_x, y| y[:iso_639_1_code] }),
    status: AccountStatusField.with_options(collection: [%w[Active active], %w[Suspended suspended]]),
    suspension_history: SuspensionHistoryField,
    account_users: Field::HasMany,
    custom_attributes: Field::String
  }.freeze

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
    status
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    created_at
    updated_at
    locale
    status
    suspension_history
    conversations
    account_users
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    locale
    status
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
  COLLECTION_FILTERS = {
    active: ->(resources) { resources.where(status: :active) },
    suspended: ->(resources) { resources.where(status: :suspended) },
    recent: ->(resources) { resources.where('created_at > ?', 30.days.ago) },
    marked_for_deletion: ->(resources) { resources.where("custom_attributes->>'marked_for_deletion_at' IS NOT NULL") }
  }.freeze

  # Overwrite this method to customize how accounts are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(account)
    "##{account.id} #{account.name}"
  end

  # We do not use the action parameter but we still need to define it
  # to prevent an error from being raised (wrong number of arguments)
  # Reference: https://github.com/thoughtbot/administrate/pull/2356/files#diff-4e220b661b88f9a19ac527c50d6f1577ef6ab7b0bed2bfdf048e22e6bfa74a05R204
  def permitted_attributes(action)
    attrs = super + [limits: {}, captain_models: {}]
    attrs += %i[suspension_category suspension_reason] if action == 'update'

    # Add manually_managed_features to permitted attributes only for Chatwoot Cloud
    attrs << { manually_managed_features: [] } if ChatwootApp.chatwoot_cloud?

    attrs
  end
end
