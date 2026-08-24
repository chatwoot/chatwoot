require 'administrate/base_dashboard'

class WhatsappTopupRequestDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    account: Field::BelongsToSearch.with_options(class_name: 'Account', searchable: true, searchable_field: [:name, :id], order: 'id DESC'),
    user: Field::BelongsToSearch.with_options(class_name: 'User', searchable: true, searchable_field: [:name, :email, :id], order: 'id DESC'),
    id: Field::Number,
    credits: Field::Number,
    status: Field::Select.with_options(collection: WhatsappTopupRequest.statuses.keys),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    account
    user
    credits
    status
    created_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    account
    user
    id
    credits
    status
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  # Only status is editable here — approving/rejecting is the only action a
  # super admin should take on a request raised by an account administrator.
  FORM_ATTRIBUTES = %i[
    status
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  COLLECTION_FILTERS = {
    pending: ->(resources) { resources.where(status: :pending) }
  }.freeze

  # Overwrite this method to customize how whatsapp topup requests are displayed
  # across all pages of the admin dashboard.
  def display_resource(whatsapp_topup_request)
    "Topup ##{whatsapp_topup_request.id} (#{whatsapp_topup_request.credits} credits)"
  end
end
