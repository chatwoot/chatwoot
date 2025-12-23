# frozen_string_literal: true

module DeviseTokenAuth::Concerns::SetUserByToken
  extend ActiveSupport::Concern
  include DeviseTokenAuth::Concerns::ResourceFinder

  included do
    before_action :set_request_start
    after_action :update_auth_header
  end

  protected

  # keep track of request duration
  def set_request_start
    @request_started_at = Time.zone.now
    @used_auth_by_token = true

    # initialize instance variables
    @token ||= DeviseTokenAuth::TokenFactory.new
    @resource ||= nil
    @is_batch_request ||= nil
  end

  # user auth
  def set_user_by_token(mapping = nil)
    # determine target authentication class
    rc = resource_class(mapping)

    # no default user defined
    return unless rc

    # gets the headers names, which was set in the initialize file
    uid_name = DeviseTokenAuth.headers_names[:'uid']
    other_uid_name = DeviseTokenAuth.other_uid && DeviseTokenAuth.headers_names[DeviseTokenAuth.other_uid.to_sym]
    access_token_name = DeviseTokenAuth.headers_names[:'access-token']
    client_name = DeviseTokenAuth.headers_names[:'client']
    authorization_name = DeviseTokenAuth.headers_names[:"authorization"]

    # Read Authorization token and decode it if present
    decoded_authorization_token = decode_bearer_token(request.headers[authorization_name])

    # gets values from cookie if configured and present
    parsed_auth_cookie = {}
    if DeviseTokenAuth.cookie_enabled
      auth_cookie = request.cookies[DeviseTokenAuth.cookie_name]
      if auth_cookie.present?
        parsed_auth_cookie = JSON.parse(auth_cookie)
      end
    end

    # parse header for values necessary for authentication
    uid              = request.headers[uid_name] || params[uid_name] || parsed_auth_cookie[uid_name] || decoded_authorization_token[uid_name]
    other_uid        = other_uid_name && request.headers[other_uid_name] || params[other_uid_name] || parsed_auth_cookie[other_uid_name]
    @token           = DeviseTokenAuth::TokenFactory.new unless @token
    @token.token     ||= request.headers[access_token_name] || params[access_token_name] || parsed_auth_cookie[access_token_name] || decoded_authorization_token[access_token_name]
    @token.client ||= request.headers[client_name] || params[client_name] || parsed_auth_cookie[client_name] || decoded_authorization_token[client_name]

    # client isn't required, set to 'default' if absent
    @token.client ||= 'default'

    # check for an existing user, authenticated via warden/devise, if enabled
    if DeviseTokenAuth.enable_standard_devise_support
      devise_warden_user = warden.user(mapping)
      if devise_warden_user && devise_warden_user.tokens[@token.client].nil?
        @used_auth_by_token = false
        @resource = devise_warden_user
        # REVIEW: The following line _should_ be safe to remove;
        #  the generated token does not get used anywhere.
        # @resource.create_new_auth_token
      end
    end

    # user has already been found and authenticated
    return @resource if @resource && @resource.is_a?(rc)

    # ensure we clear the client
    unless @token.present?
      @token.client = nil
      return
    end

    # mitigate timing attacks by finding by uid instead of auth token
    user = (uid && rc.dta_find_by(uid: uid)) || (other_uid && rc.dta_find_by("#{DeviseTokenAuth.other_uid}": other_uid))
    scope = rc.to_s.underscore.to_sym

    if user && user.valid_token?(@token.token, @token.client)
      # sign_in with bypass: true will be deprecated in the next version of Devise
      if respond_to?(:bypass_sign_in) && DeviseTokenAuth.bypass_sign_in
        bypass_sign_in(user, scope: scope)
      else
        sign_in(scope, user, store: false, event: :fetch, bypass: DeviseTokenAuth.bypass_sign_in)
      end
      return @resource = user
    else
      # zero all values previously set values
      @token.client = nil
      return @resource = nil
    end
  end

  def update_auth_header
    # cannot save object if model has invalid params
    return unless @resource && @token.client

    # Generate new client with existing authentication
    @token.client = nil unless @used_auth_by_token

    if @used_auth_by_token && !DeviseTokenAuth.change_headers_on_each_request
      # should not append auth header if @resource related token was
      # cleared by sign out in the meantime
      return if @resource.reload.tokens[@token.client].nil?

      auth_header = @resource.build_auth_headers(@token.token, @token.client)

      # update the response header
      response.headers.merge!(auth_header)

      # set a server cookie if configured
      if DeviseTokenAuth.cookie_enabled
        set_cookie(auth_header)
      end
    else
      unless @resource.reload.valid?
        @resource = @resource.class.find(@resource.to_param) # errors remain after reload
        # if we left the model in a bad state, something is wrong in our app
        unless @resource.valid?
          raise DeviseTokenAuth::Errors::InvalidModel, "Cannot set auth token in invalid model. Errors: #{@resource.errors.full_messages}"
        end
      end
      refresh_headers
    end
  end

  private

  def decode_bearer_token(bearer_token)
    return {} if bearer_token.blank?

    encoded_token = bearer_token.split.last # Removes the 'Bearer' from the string
    JSON.parse(Base64.strict_decode64(encoded_token)) rescue {}
  end

  def refresh_headers
    # Lock the user record during any auth_header updates to ensure
    # we don't have write contention from multiple threads
    @resource.with_lock do
      # should not append auth header if @resource related token was
      # cleared by sign out in the meantime
      return if @used_auth_by_token && @resource.tokens[@token.client].nil?

      _auth_header_from_batch_request = auth_header_from_batch_request

      # update the response header
      response.headers.merge!(_auth_header_from_batch_request)

      # set a server cookie if configured and is not a batch request
      if DeviseTokenAuth.cookie_enabled && !@is_batch_request
        set_cookie(_auth_header_from_batch_request)
      end
    end # end lock
  end

  def set_cookie(auth_header)
    cookies[DeviseTokenAuth.cookie_name] = DeviseTokenAuth.cookie_attributes.merge(value: auth_header.to_json)
  end

  def is_batch_request?(user, client)
    !params[:unbatch] &&
      user.tokens[client] &&
      user.tokens[client]['updated_at'] &&
      user.tokens[client]['updated_at'].to_time > @request_started_at - DeviseTokenAuth.batch_request_buffer_throttle
  end

  def auth_header_from_batch_request
    # determine batch request status after request processing, in case
    # another processes has updated it during that processing
    @is_batch_request = is_batch_request?(@resource, @token.client)

    auth_header = {}
    # extend expiration of batch buffer to account for the duration of
    # this request
    if @is_batch_request
      auth_header = @resource.extend_batch_buffer(@token.token, @token.client)

      # Do not return token for batch requests to avoid invalidated
      # tokens returned to the client in case of race conditions.
      # Use a blank string for the header to still be present and
      # being passed in a XHR response in case of
      # 304 Not Modified responses.
      auth_header[DeviseTokenAuth.headers_names[:"access-token"]] = ' '
      auth_header[DeviseTokenAuth.headers_names[:"expiry"]] = ' '
    else
      # update Authorization response header with new token
      auth_header = @resource.create_new_auth_token(@token.client)
    end
    auth_header
  end
end
