# frozen_string_literal: true

require 'administrate/base_dashboard'

class CustomRoleDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    name: Field::String,
    description: Field::Text,
    permissions: PermissionsField,
    account_users: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    account
    name
    permissions
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    name
    description
    permissions
    account_users
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    account
    name
    description
    permissions
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(custom_role)
    "##{custom_role.id} - #{custom_role.name}"
  end
end

