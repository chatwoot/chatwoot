# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.
# Copyright, 2022, by Jeremy Evans.

module Rack
  module Session
    autoload :Cookie, "rack/session/cookie"
    autoload :Pool, "rack/session/pool"
    autoload :Memcache, "rack/session/memcache"
  end
end
