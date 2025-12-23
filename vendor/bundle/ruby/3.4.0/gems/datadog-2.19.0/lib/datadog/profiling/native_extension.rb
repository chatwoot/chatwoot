# frozen_string_literal: true

module Datadog
  module Profiling
    # This module contains classes and methods which are implemented using native code in the
    # ext/datadog_profiling_native_extension folder, as well as some Ruby-level utilities that don't make sense to
    # write using C
    module NativeExtension
      private_class_method def self.working?
        native_working?
      end

      unless singleton_class.private_method_defined?(:native_working?)
        private_class_method def self.native_working?
          false
        end
      end
    end
  end
end
