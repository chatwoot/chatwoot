module AuthHelper
  def send_auth_headers(user)
    data = user.create_new_auth_token
    response.headers[DeviseTokenAuth.headers_names[:'access-token']] = data['access-token']
    response.headers[DeviseTokenAuth.headers_names[:'token-type']]   = 'Bearer'
    response.headers[DeviseTokenAuth.headers_names[:client]]       = data['client']
    response.headers[DeviseTokenAuth.headers_names[:expiry]]       = data['expiry']
    response.headers[DeviseTokenAuth.headers_names[:uid]]          = data['uid']
  end
end
