module Hashie
  module Extensions
    module Mash
      module SafeAssignment
        def custom_writer(key, *args) #:nodoc:
          if !key?(key) && respond_to?(key, true)
            raise ArgumentError, "The property #{key} clashes with an existing method."
          end
          super
        end

        def []=(*args)
          custom_writer(*args)
        end
      end
    end
  end
end
