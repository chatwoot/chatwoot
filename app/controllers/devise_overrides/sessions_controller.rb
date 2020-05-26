class DeviseOverrides::SessionsController < ::DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []

  def render_create_success
    render partial: 'devise/auth.json', locals: { resource: @resource }
  end
end
