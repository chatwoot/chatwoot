require "administrate/base_dashboard"

class EmailTemplateDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String.with_options(searchable: true),
    slug: Field::String.with_options(searchable: true),
    account: Field::BelongsTo.with_options(
      class_name: "Account",
      searchable: true,
      searchable_field: 'name'
    ),
    body: Field::Text.with_options(
      searchable: false,
      truncate: 50,
      limit: 20_000,
    ),
    subject: Field::String,
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
    slug
    account
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    subject
    body
    account
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    slug
    subject
    body
    account
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
    recent: ->(resources) { resources.where('created_at > ?', 30.days.ago) }
  }.freeze

  # Overwrite this method to customize how email templates are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(email_template)
    "#{email_template.name} (#{email_template.account&.name})"
  end
end
