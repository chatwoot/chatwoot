# Global configuration for Koala.
class Koala::Configuration
  # The default access token to be used if none is otherwise supplied.
  attr_accessor :access_token

  # The default app secret value to be used if none is otherwise supplied.
  attr_accessor :app_secret

  # The default application ID to use if none is otherwise supplied.
  attr_accessor :app_id

  # The default app access token to be used if none is otherwise supplied.
  attr_accessor :app_access_token

  # The default API version to use if none is otherwise specified.
  attr_accessor :api_version

  # The default value to use for the oauth_callback_url if no other is provided.
  attr_accessor :oauth_callback_url

  # Whether to preserve arrays in arguments, which are expected by certain FB APIs (see the ads API
  # in particular, https://developers.facebook.com/docs/marketing-api/adgroup/v2.4)
  attr_accessor :preserve_form_arguments

  # The server to use for Graph API requests
  attr_accessor :graph_server

  # The server to use when constructing dialog URLs.
  attr_accessor :dialog_host

  # Whether or not to mask tokens
  attr_accessor :mask_tokens

  # Called with the info for the rate limits in the response header
  attr_accessor :rate_limit_hook

  # Certain Facebook services (beta, video) require you to access different
  # servers. If you're using your own servers, for instance, for a proxy,
  # you can change both the matcher (what value to change when updating the URL) and the
  # replacement values (what to add).
  #
  # So, for instance, to use the beta stack, we match on .facebook and change it to .beta.facebook.
  # If you're talking to fbproxy.mycompany.com, you could set up beta.fbproxy.mycompany.com for
  # FB's beta tier, and set the matcher to /\.fbproxy/ and the beta_replace to '.beta.fbproxy'.
  attr_accessor :host_path_matcher
  attr_accessor :video_replace
  attr_accessor :beta_replace

  def initialize
    # Default to our default values.
    Koala::HTTPService::DEFAULT_SERVERS.each_pair do |key, value|
      self.public_send("#{key}=", value)
    end
    self.mask_tokens = true
  end
end
