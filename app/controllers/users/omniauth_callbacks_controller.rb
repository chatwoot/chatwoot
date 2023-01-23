class Users::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  def omniauth_success
    get_resource_from_auth_hash
    set_token_on_resource
    create_auth_params

    if confirmable_enabled?
      # don't send confirmation email!!!
      @resource.skip_confirmation!
    end
    
    sign_in(:user, @resource, store: false, bypass: false)
    @resource.save!

    yield @resource if block_given?

    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  def resource_class(mapping = nil)
    User
  end

  def default_devise_mapping
    'user'
  end
end
