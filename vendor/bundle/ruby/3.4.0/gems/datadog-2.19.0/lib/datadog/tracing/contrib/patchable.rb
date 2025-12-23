# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Base provides features that are shared across all integrations
      module Patchable
        def self.included(base)
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        # Class methods for integrations
        # @public_api
        module ClassMethods
          # Version of the integration target code in the environment.
          #
          # This is the gem version, when the instrumentation target is a Ruby gem.
          #
          # If the target for instrumentation has concept of versioning, override {.version},
          # otherwise override {.available?} and implement a custom target presence check.
          # @return [Object] the target version
          def version
            nil
          end

          # Is the target available to be instrumented? (e.g. gem installed?)
          #
          # The target doesn't have to be loaded (e.g. `require`) yet, but needs to be able
          # to be loaded before instrumentation can commence.
          #
          # By default, {.available?} checks if {.version} returned a non-nil object.
          #
          # If the target for instrumentation has concept of versioning, override {.version},
          # otherwise override {.available?} and implement a custom target presence check.
          # @return [Boolean] is the target available for instrumentation in this Ruby environment?
          def available?
            !version.nil?
          end

          # Is the target loaded into the application? (e.g. gem required? Constant defined?)
          #
          # The target's objects should be ready to be referenced by the instrumented when {.loaded}
          # returns `true`.
          #
          # @return [Boolean] is the target ready to be referenced during instrumentation?
          def loaded?
            true
          end

          # Is this instrumentation compatible with the available target? (e.g. minimum version met?)
          # @return [Boolean] is the available target compatible with this instrumentation?
          def compatible?
            available?
          end

          # Can the patch for this integration be applied?
          #
          # By default, this is equivalent to {#available?}, {#loaded?}, and {#compatible?}
          # all being truthy.
          def patchable?
            available? && loaded? && compatible?
          end
        end

        # Instance methods for integrations
        # @public_api
        module InstanceMethods
          # The patcher module to inject instrumented objects into the instrumentation target.
          #
          # {Contrib::Patcher} includes the basic functionality of a patcher. `include`ing
          # {Contrib::Patcher} into a new module is the recommend way to create a custom patcher.
          #
          # @return [Contrib::Patcher] a module that `include`s {Contrib::Patcher}
          def patcher
            nil
          end

          # @!visibility private
          def patch
            if !self.class.patchable? || patcher.nil?
              return {
                name: self.class.name,
                available: self.class.available?,
                loaded: self.class.loaded?,
                compatible: self.class.compatible?,
                patchable: self.class.patchable?
              }
            end

            patcher.patch
            true
          end

          # Can the patch for this integration be applied automatically?
          # For example: test integrations should only be applied
          # by the user explicitly setting `c.ci.instrument :rspec`
          # and rails sub-modules are auto-instrumented by enabling rails
          # so auto-instrumenting them on their own will cause changes in
          # service naming behavior
          # @return [Boolean] can the tracer activate this instrumentation without explicit user input?
          def auto_instrument?
            true
          end
        end
      end
    end
  end
end
