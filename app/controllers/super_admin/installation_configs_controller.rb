class SuperAdmin::InstallationConfigsController < SuperAdmin::ApplicationController
  rescue_from ActiveRecord::RecordNotUnique, :with => :invalid_action_perfomed
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  #
  def update
    @resource = InstallationConfig.find(params[:id])
    new_values = params.dig(:installation_config, :value) || []
    formatted_new_values = format_new_values(new_values)
    updated_values = update_existing_values(@resource.value || [], formatted_new_values)

    if @resource.update(value: updated_values)
      redirect_to super_admin_installation_config_path(@resource), notice: 'Updated successfully'
    else
      render :edit
    end
  end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  def scoped_resource
    resource_class
  end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  # def resource_params
  #   params.require(resource_class.model_name.param_key).
  #     permit(dashboard.permitted_attributes).
  #     transform_values { |value| value == "" ? nil : value }
  # end

  def resource_params
    params.require(:installation_config)
          .permit(:name, :value)
          .transform_values { |value| value == '' ? nil : value }.merge(locked: false)
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  private

  # Format new values by extracting relevant data and applying boolean conversion where necessary
  def format_new_values(new_values)
    new_values.values.map do |value|
      {
        'name' => value['name'],
        'display_name' => value['display_name'],
        'enabled' => boolean_value(value['enabled']),
        'help_url' => value['help_url'],
        'premium' => boolean_value(value['premium']),
        'deprecated' => boolean_value(value['deprecated']),
        'chatwoot_internal' => boolean_value(value['chatwoot_internal'])
      }.compact
    end
  end

  # Convert string to boolean if it's a "true" or "false" string, else return the original value
  def boolean_value(value)
    return true if value == 'true'
    return false if value == 'false'

    value
  end

  # Update existing values by merging with formatted new values if names match
  def update_existing_values(existing_values, formatted_new_values)
    existing_values.map do |existing|
      new_value = formatted_new_values.find { |v| v['name'] == existing['name'] }
      new_value ? existing.merge(new_value) : existing
    end
  end
end
