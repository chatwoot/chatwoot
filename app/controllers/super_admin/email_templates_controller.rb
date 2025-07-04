class SuperAdmin::EmailTemplatesController < SuperAdmin::ApplicationController
  def create
    resource = resource_class.new(resource_params)
    authorize_resource(resource)

    if resource.save
      redirect_to(
        after_resource_created_path(resource),
        notice: translate_with_resource("create.success")
      )
    else
      render :new, locals: {
        page: Administrate::Page::Form.new(dashboard, resource),
      }, status: :unprocessable_entity
    end
  end

  def update
    if requested_resource.update(resource_params)
      redirect_to(
        after_resource_updated_path(requested_resource),
        notice: translate_with_resource("update.success")
      )
    else
      render :edit, locals: {
        page: Administrate::Page::Form.new(dashboard, requested_resource),
      }, status: :unprocessable_entity
    end
  end

  def check_slug_inbox
    exists = EmailTemplate.exists?(slug: params[:slug], account_id: params[:account_id])
    render json: { exists: exists }
  end

  private

  def find_existing_template(resource)
    EmailTemplate.find_by(slug: resource.slug, inbox: resource.inbox)
  end

  def resource_params
    params.require(resource_class.model_name.param_key).
      permit(dashboard.permitted_attributes(action_name)).
      transform_values { |value| value == "" ? nil : value }
  end
end 