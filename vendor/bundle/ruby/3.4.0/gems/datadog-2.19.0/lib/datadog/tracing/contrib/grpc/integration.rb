# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        # Description of gRPC integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('1.7.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :grpc, auto_patch: true

          def self.version
            Gem.loaded_specs['grpc'] && Gem.loaded_specs['grpc'].version
          end

          def self.loaded?
            !defined?(::GRPC).nil? &&
              # When using the Google "Calendar User Availability API"
              # (https://developers.google.com/calendar/api/user-availability/reference/rest), though the gem
              # `google-cloud-calendar-useravailability-v1alpha` (currently in private preview),
              # it's possible to load `GRPC` without loading the rest of the `grpc` gem. See:
              # https://github.com/googleapis/gapic-generator-ruby/blob/f1c2e73219453e497b6ec2dc807a907e939e1342/gapic-common/lib/gapic/common.rb#L15-L16
              # When this happens, there are no gRPC components of interest to instrument.
              !defined?(::GRPC::Interceptor).nil? && !defined?(::GRPC::InterceptionContext).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
