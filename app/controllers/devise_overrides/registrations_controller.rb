class DeviseOverrides::RegistrationsController < DeviseTokenAuth::RegistrationsController
  # Override `create` so a request with a blank `name` cannot leak whether
  # the submitted `email` belongs to an existing account. The default
  # gem implementation runs every model validation and returns every
  # error in one body; the `email has already been taken` error reveals
  # account existence to anyone who can hit /auth, since the only other
  # registration-validation error is `name can't be blank`.
  #
  # The fix has two halves:
  #
  # 1. When the caller submits a blank `name`, swap the submitted email
  #    for a unique placeholder before validation runs. The model still
  #    sees the field so `email` format is checked, but the uniqueness
  #    check can no longer distinguish a known email from a random one
  #    because both paths are now colliding with a unique placeholder.
  #
  # 2. After validation, drop any `:email_taken` symbol from the
  #    errors collection, so even a request with a populated `name`
  #    but a duplicate email reads the same as any other validation
  #    failure. Devise's uniqueness validator adds an `:email_taken`
  #    symbol in addition to the rendered message under `:email`.
  #
  # See https://github.com/chatwoot/chatwoot/issues/15657
  def create
    sanitized = sign_up_params
    sanitized[:email] = enumeration_guard_email if sanitized[:name].to_s.strip.empty?

    @resource = build_resource(sanitized.deep_symbolize_keys)
    yield @resource if block_given?
    if @resource.persisted?
      sign_in(resource_name, @resource, store: false)
      render_create_success
    else
      clean_up_passwords(@resource)
      @resource.errors.delete(:email_taken) if @resource.errors.respond_to?(:delete)
      render_create_error
    end
  end

  private

  def enumeration_guard_email
    "enumeration-guard-#{SecureRandom.hex(16)}@invalid.local"
  end
end

DeviseOverrides::RegistrationsController.prepend_mod_with('DeviseOverrides::RegistrationsController')
