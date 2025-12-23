module Shoulda
  module Matchers
    module Doublespeak
      # @private
      class Double
        attr_reader :calls

        def initialize(world, klass, method_name, implementation)
          @world = world
          @klass = klass
          @method_name = method_name
          @implementation = implementation
          @activated = false
          @calls = []

          if world.doubles_activated?
            activate
          end
        end

        def activated?
          @activated
        end

        def to_return(value = nil, &block)
          if block
            implementation.returns(&block)
          else
            implementation.returns(value)
          end
        end

        def activate
          unless @activated
            store_original_method
            replace_method_with_double
            @activated = true
          end
        end

        def deactivate
          if @activated
            restore_original_method
            @activated = false
          end
        end

        def record_call(call)
          calls << call
        end

        def call_original_method(call)
          unbound_method = world.original_method_for(klass, call.method_name)

          if unbound_method
            unbound_method.bind(call.object).call(*call.args, &call.block)
          end
        end

        protected

        attr_reader :world, :klass, :method_name, :implementation,
          :original_method

        def store_original_method
          world.store_original_method_for(klass, method_name)
        end

        def replace_method_with_double
          double = self
          implementation = @implementation
          _method_name = method_name

          if klass.instance_methods(false).include?(method_name)
            klass.__send__(:remove_method, method_name)
          end

          klass.__send__(:define_method, method_name) do |*args, &block|
            call = MethodCall.new(
              double: double,
              object: self,
              method_name: _method_name,
              args: args,
              block: block,
              caller: caller,
            )
            implementation.call(call)
          end
        end

        def restore_original_method
          original_method = world.original_method_for(klass, method_name)

          klass.__send__(:remove_method, method_name)

          klass.__send__(:define_method, method_name) do |*args, &block|
            original_method.bind(self).call(*args, &block)
          end
        end
      end
    end
  end
end
