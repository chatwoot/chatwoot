require 'administrate/base_dashboard'

class ResponseSourceDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number.with_options(searchable: true),
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable_field: [:name, :id], order: 'id DESC'),
    name: Field::String.with_options(searchable: true),
    response_documents: Field::HasMany,
    responses: Field::HasMany,
    source_link: Field::String.with_options(searchable: true),
    source_model_id: Field::Number,
    source_model_type: Field::String,
    source_type: Field::Select.with_options(searchable: false, collection: lambda { |field|
                                                                             field.resource.class.send(field.attribute.to_s.pluralize).keys
                                                                           }),
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
    source_link
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    account
    source_link
    source_model_id
    source_model_type
    source_type
    created_at
    updated_at
    response_documents
    responses
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    account
    name
    source_link
    source_model_id
    source_model_type
    source_type
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
    account: ->(resources, attr) { resources.where(account_id: attr) }
  }.freeze

  # Overwrite this method to customize how response sources are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(response_source)
    "Source: ##{response_source.id} - #{response_source.name}"
  end
end
