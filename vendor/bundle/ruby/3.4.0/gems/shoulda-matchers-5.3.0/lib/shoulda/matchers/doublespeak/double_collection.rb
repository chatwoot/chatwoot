module Shoulda
  module Matchers
    module Doublespeak
      # @private
      class DoubleCollection
        def initialize(world, klass)
          @world = world
          @klass = klass
          @doubles_by_method_name = {}
        end

        def register_stub(method_name)
          register_double(method_name, :stub)
        end

        def register_proxy(method_name)
          register_double(method_name, :proxy)
        end

        def activate
          doubles_by_method_name.each do |_method_name, double|
            double.activate
          end
        end

        def deactivate
          doubles_by_method_name.each do |_method_name, double|
            double.deactivate
          end
        end

        def calls_by_method_name
          doubles_by_method_name.inject({}) do |hash, (method_name, double)|
            hash.merge method_name => double.calls.map(&:args)
          end
        end

        def calls_to(method_name)
          double = doubles_by_method_name[method_name]

          if double
            double.calls
          else
            []
          end
        end

        protected

        attr_reader :world, :klass, :doubles_by_method_name

        def register_double(method_name, implementation_type)
          doubles_by_method_name.fetch(method_name) do
            implementation =
              DoubleImplementationRegistry.find(implementation_type)
            double = Double.new(world, klass, method_name, implementation)
            doubles_by_method_name[method_name] = double
            double
          end
        end
      end
    end
  end
end
