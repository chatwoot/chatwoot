module Bundler
  module Audit
    module Results
      #
      # @abstract
      #
      class Result

        #
        # @return [Hash{Symbol => Object}]
        #
        # @abstract
        #
        def to_h
          raise(NotImplementedError,"#{self.class}#to_h not implemented!")
        end

      end
    end
  end
end
