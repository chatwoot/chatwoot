module Shoulda
  module Matchers
    module ActiveModel
      module Qualifiers
        # @private
        module IgnoringInterferenceByWriter
          attr_reader :ignore_interference_by_writer

          def initialize(*)
            @ignore_interference_by_writer = IgnoreInterferenceByWriter.new
          end

          def ignoring_interference_by_writer(value = :always)
            @ignore_interference_by_writer.set(value)
            self
          end
        end
      end
    end
  end
end
