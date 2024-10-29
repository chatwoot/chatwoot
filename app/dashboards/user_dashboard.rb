require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    account_users: Field::HasMany,
    id: Field::Number.with_options(searchable: true),
    avatar_url: AvatarField,
    avatar: Field::ActiveStorage.with_options(
      destroy_url: proc do |_namespace, _resource, attachment|
        [:avatar_super_admin_user, { attachment_id: attachment.id }]
      end
    ),
    provider: Field::String,
    uid: Field::String,
    password: Field::Password,
    sign_in_count: Field::Number,
    current_sign_in_at: Field::DateTime,
    last_sign_in_at: Field::DateTime,
    current_sign_in_ip: Field::String,
    last_sign_in_ip: Field::String,
    confirmation_token: Field::String,
    confirmed_at: Field::DateTime,
    confirmation_sent_at: Field::DateTime,
    unconfirmed_email: Field::String,
    name: Field::String.with_options(searchable: true),
    display_name: Field::String,
    email: Field::String.with_options(searchable: true),
    tokens: Field::String.with_options(searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    pubsub_token: Field::String,
    type: Field::Select.with_options(collection: [nil, 'SuperAdmin']),
    accounts: CountField,
    access_token: Field::HasOne
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    avatar_url
    name
    email
    accounts
    type
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    avatar_url
    unconfirmed_email
    name
    type
    display_name
    email
    created_at
    updated_at
    confirmed_at
    account_users
    access_token
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    avatar
    display_name
    email
    password
    confirmed_at
    type
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
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(user)
    "##{user.id} #{user.name}"
  end
end
