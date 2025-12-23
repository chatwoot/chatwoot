# frozen_string_literal: true

# third party gems
require "snaky_hash"
require "version_gem"

require "oauth/version"

require "oauth/oauth"

require "oauth/client/helper"
require "oauth/signature/plaintext"
require "oauth/signature/hmac/sha1"
require "oauth/signature/hmac/sha256"
require "oauth/signature/rsa/sha1"
require "oauth/request_proxy/mock_request"

OAuth::Version.class_eval do
  extend VersionGem::Basic
end
