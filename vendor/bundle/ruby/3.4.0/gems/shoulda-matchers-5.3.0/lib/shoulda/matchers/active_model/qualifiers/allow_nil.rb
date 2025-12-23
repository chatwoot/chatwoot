module Shoulda
  module Matchers
    module ActiveModel
      module Qualifiers
        # @private
        module AllowNil
          def initialize(*args)
            super
            @expects_to_allow_nil = false
          end

          def allow_nil
            @expects_to_allow_nil = true
            self
          end

          protected

          def expects_to_allow_nil?
            @expects_to_allow_nil
          end
        end
      end
    end
  end
end
