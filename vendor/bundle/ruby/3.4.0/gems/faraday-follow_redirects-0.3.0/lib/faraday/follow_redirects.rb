# frozen_string_literal: true

require 'faraday'
require_relative 'follow_redirects/middleware'
require_relative 'follow_redirects/redirect_limit_reached'
require_relative 'follow_redirects/version'

module Faraday
  # Main Faraday::FollowRedirects module.
  module FollowRedirects
    Faraday::Response.register_middleware(follow_redirects: Faraday::FollowRedirects::Middleware)
  end
end
