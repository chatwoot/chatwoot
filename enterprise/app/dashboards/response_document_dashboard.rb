require 'administrate/base_dashboard'

class ResponseDocumentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number.with_options(searchable: true),
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable_field: [:name, :id], order: 'id DESC'),
    content: Field::Text.with_options(searchable: true),
    document_id: Field::Number,
    document_link: Field::String.with_options(searchable: true),
    document_type: Field::String,
    response_source: Field::BelongsToSearch.with_options(class_name: 'ResponseSource', searchable_field: [:name, :id, :source_link],
                                                         order: 'id DESC'),
    responses: Field::HasMany,
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
    response_source
    document_link
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    response_source
    document_link
    document_id
    document_type
    content
    created_at
    updated_at
    responses
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    account
    response_source
    document_link
    document_id
    document_type
    content
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
    account: ->(resources, attr) { resources.where(account_id: attr) },
    response_source: ->(resources, attr) { resources.where(response_source_id: attr) }
  }.freeze

  # Overwrite this method to customize how response documents are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(response_document)
    "Document: ##{response_document.id} - #{response_document.document_link}"
  end
end
