module Shoulda
  module Matchers
    module Doublespeak
      # @private
      class World
        def initialize
          @doubles_activated = false
        end

        def double_collection_for(klass)
          double_collections_by_class[klass] ||=
            DoubleCollection.new(self, klass)
        end

        def store_original_method_for(klass, method_name)
          original_methods_for_class(klass)[method_name] ||=
            klass.instance_method(method_name)
        end

        def original_method_for(klass, method_name)
          if original_methods_by_class.key?(klass)
            original_methods_by_class[klass][method_name]
          end
        end

        def with_doubles_activated
          @doubles_activated = true
          activate
          yield
        ensure
          @doubles_activated = false
          deactivate
        end

        def doubles_activated?
          @doubles_activated
        end

        private

        def activate
          double_collections_by_class.each do |_klass, double_collection|
            double_collection.activate
          end
        end

        def deactivate
          double_collections_by_class.each do |_klass, double_collection|
            double_collection.deactivate
          end
        end

        def double_collections_by_class
          @_double_collections_by_class ||= {}
        end

        def original_methods_by_class
          @_original_methods_by_class ||= {}
        end

        def original_methods_for_class(klass)
          original_methods_by_class[klass] ||= {}
        end
      end
    end
  end
end
