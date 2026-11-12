require 'administrate/field/belongs_to'

class BelongsToSearchField < Administrate::Field::BelongsTo
  def associated_resource_options
    return [] unless data

    [[display_associated_resource, selected_option]]
  end
end
