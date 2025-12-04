require 'administrate/base_dashboard'

class AccountEmailTemplateDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    name: Field::String,
    friendly_name: Field::String,
    description: Field::Text,
    template_type: Field::String,
    html: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    account
    name
    friendly_name
    template_type
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    account
    name
    friendly_name
    description
    template_type
    html
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    account
    name
    friendly_name
    description
    template_type
    html
  ].freeze

  def display_resource(account_email_template)
    account_email_template.name
  end
end
