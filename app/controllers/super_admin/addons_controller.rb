class SuperAdmin::AddonsController < SuperAdmin::ApplicationController
  # Administrate provides the full CRUD actions (index, show, new, create,
  # edit, update, destroy) for the Addon resource.
  #
  # A blank limit field is stored as nil ("no boost") so an empty input does not
  # fail the numericality validation on the Addon model.
  def resource_params
    params.require(resource_class.model_name.param_key)
          .permit(dashboard.permitted_attributes)
          .transform_values(&:presence)
  end
end
