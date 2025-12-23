module Shoulda
  module Matchers
    module Integrations
      # @private
      module Rails
        def rails?
          true
        end
      end
    end
  end
end
