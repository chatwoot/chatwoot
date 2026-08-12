class SuperAdmin::PackagesController < SuperAdmin::ApplicationController
  # Administrate provides the full CRUD actions (index, show, new, create,
  # edit, update, destroy) for the Package resource.
  #
  # A blank limit field is stored as nil (unlimited) so an empty input does not
  # fail the numericality validation on the Package model.
  def resource_params
    params.require(resource_class.model_name.param_key)
          .permit(dashboard.permitted_attributes)
          .transform_values { |value| value.blank? ? nil : value }
  end
end
