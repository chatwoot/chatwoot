# frozen_string_literal: true

class SuperAdmin::CustomRolesController < SuperAdmin::ApplicationController
  # Override resource_params to permit permissions array
  def resource_params
    params.require(resource_class.model_name.param_key)
          .permit(dashboard.permitted_attributes, permissions: [])
          .tap do |whitelisted|
      # Remove empty string from permissions array (comes from hidden field)
      whitelisted[:permissions]&.reject!(&:blank?)
    end
  end
end

