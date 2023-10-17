require 'administrate/base_dashboard'

class ResponseDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number.with_options(searchable: true),
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable_field: [:name, :id], order: 'id DESC'),
    response_source: Field::BelongsToSearch.with_options(class_name: 'ResponseSource', searchable_field: [:name, :id, :source_link],
                                                         order: 'id DESC'),
    answer: Field::Text.with_options(searchable: true),
    question: Field::String.with_options(searchable: true),
    status: Field::Select.with_options(searchable: false, collection: lambda { |field|
      field.resource.class.send(field.attribute.to_s.pluralize).keys
    }),
    response_document: Field::BelongsToSearch.with_options(class_name: 'ResponseDocument', searchable_field: [:document_link, :content, :id],
                                                           order: 'id DESC'),
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
    question
    answer
    status
    response_document
    response_source
    account
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    status
    question
    answer
    response_document
    response_source
    account
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    response_source
    response_document
    question
    answer
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
    account: ->(resources, attr) { resources.where(account_id: attr) },
    response_source: ->(resources, attr) { resources.where(response_source_id: attr) },
    response_document: ->(resources, attr) { resources.where(response_document_id: attr) },
    status: ->(resources, attr) { resources.where(status: attr) }
  }.freeze

  # Overwrite this method to customize how responses are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(response)
    "Response: ##{response.id} - #{response.question}"
  end
end
