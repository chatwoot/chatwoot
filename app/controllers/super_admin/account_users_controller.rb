class SuperAdmin::AccountUsersController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  def create
    resource = resource_class.new(resource_params)
    authorize_resource(resource)

    notice = resource.save ? translate_with_resource('create.success') : resource.errors.full_messages.first
    redirect_back(fallback_location: [namespace, resource.account], notice: notice)
  end

  def destroy
    if requested_resource.destroy
      flash[:notice] = translate_with_resource('destroy.success')
    else
      flash[:error] = requested_resource.errors.full_messages.join('<br/>')
    end
    redirect_back(fallback_location: [namespace, requested_resource.account])
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
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

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

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information
end
