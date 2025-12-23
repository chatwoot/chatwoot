# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/apis/core/version'
require 'logger'
require 'open3'

module Google
  module Apis
    ROOT = File.expand_path('..', File.dirname(__dir__))

    # Current operating system
    # @private
    OS_VERSION = begin
      if RUBY_PLATFORM =~ /mswin|win32|mingw|bccwin|cygwin/
        output, _ = Open3.capture2('ver')
        output.sub(/\s*\[Version\s*/, '/').sub(']', '')
      elsif RUBY_PLATFORM =~ /darwin/i
        output, _ = Open3.capture2('sw_vers', '-productVersion')
        "Mac OS X/#{output}"
      elsif RUBY_PLATFORM == 'java'
        require 'java'
        name = java.lang.System.getProperty('os.name')
        version = java.lang.System.getProperty('os.version')
        "#{name}/#{version}"
      else
        output, _ = Open3.capture2('uname', '-sr')
        output.sub(' ', '/')
      end.strip
    rescue
      RUBY_PLATFORM
    end

    # @!attribute [rw] logger
    # @return [Logger] The logger.
    def self.logger
      @logger ||= rails_logger || default_logger
    end

    class << self
      attr_writer :logger
    end

    private

    # Create and configure a logger
    # @return [Logger]
    def self.default_logger
      logger = Logger.new($stdout)
      logger.level = Logger::WARN
      logger
    end

    # Check to see if client is being used in a Rails environment and get the logger if present.
    # Setting the ENV variable 'GOOGLE_API_USE_RAILS_LOGGER' to false will force the client
    # to use its own logger.
    #
    # @return [Logger]
    def self.rails_logger
      if 'true' == ENV.fetch('GOOGLE_API_USE_RAILS_LOGGER', 'true') &&
          defined?(::Rails) &&
          ::Rails.respond_to?(:logger) &&
          !::Rails.logger.nil?
        ::Rails.logger
      else
        nil
      end
    end
  end
end
