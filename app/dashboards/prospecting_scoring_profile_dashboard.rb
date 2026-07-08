require 'administrate/base_dashboard'

class ProspectingScoringProfileDashboard < Administrate::BaseDashboard
  def self.resource_class
    Autonomia::Prospecting::ScoringProfile
  end

  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    default: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    default
    updated_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    default
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    default
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(profile)
    profile.name
  end
end
