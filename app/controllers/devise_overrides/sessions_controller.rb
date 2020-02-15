class DeviseOverrides::SessionsController < ::DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []

  def render_create_success
    render 'devise/auth.json'
  end
end
