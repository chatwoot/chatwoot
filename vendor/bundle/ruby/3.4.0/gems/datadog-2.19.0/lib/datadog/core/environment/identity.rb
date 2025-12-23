# frozen_string_literal: true

require 'securerandom'

require_relative 'ext'
require_relative '../utils/forking'

module Datadog
  module Core
    module Environment
      # For runtime identity
      # @public_api
      module Identity
        extend Core::Utils::Forking

        module_function

        # Retrieves number of classes from runtime
        def id
          @id ||= ::SecureRandom.uuid.freeze

          # Check if runtime has changed, e.g. forked.
          after_fork! { @id = ::SecureRandom.uuid.freeze }

          @id
        end

        def pid
          ::Process.pid
        end

        def lang
          Core::Environment::Ext::LANG
        end

        def lang_engine
          Core::Environment::Ext::LANG_ENGINE
        end

        def lang_interpreter
          Core::Environment::Ext::LANG_INTERPRETER
        end

        def lang_platform
          Core::Environment::Ext::LANG_PLATFORM
        end

        def lang_version
          Core::Environment::Ext::LANG_VERSION
        end

        # Returns datadog gem version, rubygems-style
        def gem_datadog_version
          Core::Environment::Ext::GEM_DATADOG_VERSION
        end

        # Returns tracer version, comforming to https://semver.org/spec/v2.0.0.html
        def gem_datadog_version_semver2
          major, minor, patch, rest = gem_datadog_version.split('.', 4)

          semver = "#{major}.#{minor}.#{patch}"

          return semver unless rest

          pre = ''
          build = ''

          rest.split('.').tap do |segments|
            if segments.length >= 4
              pre = "-#{segments.shift}"
              build = "+#{segments.join(".")}"
            elsif segments.length == 1
              pre = "-#{segments.shift}"
            else
              build = "+#{segments.join(".")}"
            end
          end

          semver + pre + build
        end
      end
    end
  end
end
