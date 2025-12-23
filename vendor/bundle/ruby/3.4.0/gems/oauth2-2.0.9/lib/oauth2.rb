# frozen_string_literal: true

# includes modules from stdlib
require 'cgi'
require 'time'

# third party gems
require 'snaky_hash'
require 'version_gem'

# includes gem files
require 'oauth2/version'
require 'oauth2/error'
require 'oauth2/authenticator'
require 'oauth2/client'
require 'oauth2/strategy/base'
require 'oauth2/strategy/auth_code'
require 'oauth2/strategy/implicit'
require 'oauth2/strategy/password'
require 'oauth2/strategy/client_credentials'
require 'oauth2/strategy/assertion'
require 'oauth2/access_token'
require 'oauth2/response'

# The namespace of this library
module OAuth2
  DEFAULT_CONFIG = SnakyHash::SymbolKeyed.new(silence_extra_tokens_warning: false)
  @config = DEFAULT_CONFIG.dup
  class << self
    attr_accessor :config
  end
  def configure
    yield @config
  end
  module_function :configure
end

OAuth2::Version.class_eval do
  extend VersionGem::Basic
end
