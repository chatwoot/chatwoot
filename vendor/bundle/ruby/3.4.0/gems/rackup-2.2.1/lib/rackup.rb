# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require_relative 'rackup/handler'
require_relative 'rackup/server'
require_relative 'rackup/version'

begin
  # Although webrick is gone from Ruby since 3.0, it still warns all the way
  # through to 3.3. Only on 3.4 will requiring it not produce a warning anymore.
  verbose, $VERBOSE = $VERBOSE, nil
  require 'webrick'
  # If the user happens to have webrick in their bundle, make the handler available.
  require_relative 'rackup/handler/webrick'
rescue LoadError
  # ¯\_(ツ)_/¯
ensure
  $VERBOSE = verbose
end
