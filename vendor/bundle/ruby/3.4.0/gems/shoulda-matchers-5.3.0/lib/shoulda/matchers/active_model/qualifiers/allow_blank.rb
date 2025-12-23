module Shoulda
  module Matchers
    module ActiveModel
      module Qualifiers
        # @private
        module AllowBlank
          def initialize(*args)
            super
            @expects_to_allow_blank = false
          end

          def allow_blank
            @expects_to_allow_blank = true
            self
          end

          protected

          def expects_to_allow_blank?
            @expects_to_allow_blank
          end
        end
      end
    end
  end
end
