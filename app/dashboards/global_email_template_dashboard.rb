require 'administrate/base_dashboard'

class GlobalEmailTemplateDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    friendly_name: Field::String,
    description: Field::Text,
    template_type: Field::String,
    html: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    friendly_name
    template_type
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    name
    friendly_name
    description
    template_type
    html
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    friendly_name
    description
    template_type
    html
  ].freeze

  def display_resource(global_email_template)
    global_email_template.name
  end
end
