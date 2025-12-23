# frozen_string_literal: true

require_relative 'ext'
require_relative 'parsers'
require_relative 'subscribers'

module Datadog
  module Tracing
    module Contrib
      module MongoDB
        # Instrumentation for Mongo integration
        module Instrumentation
          # Instrumentation for Mongo::Client
          module Client
            def self.included(base)
              base.include(InstanceMethods)
            end

            # Instance methods for Mongo::Client
            module InstanceMethods
              def datadog_pin
                # safe-navigation to avoid crashes during each query
                return unless respond_to? :cluster
                return unless cluster.respond_to? :addresses
                return unless cluster.addresses.respond_to? :first

                Datadog.configuration_for(cluster.addresses.first)
              end

              def datadog_pin=(pin)
                # safe-navigation to avoid crashes during each query
                return unless respond_to? :cluster
                return unless cluster.respond_to? :addresses
                return unless cluster.addresses.respond_to? :each

                # attach the PIN to all cluster addresses. One of them is used
                # when executing a Command and it is attached to the Monitoring
                # Event instance.
                cluster.addresses.each { |x| pin.onto(x) }
              end
            end
          end
        end
      end
    end
  end
end
