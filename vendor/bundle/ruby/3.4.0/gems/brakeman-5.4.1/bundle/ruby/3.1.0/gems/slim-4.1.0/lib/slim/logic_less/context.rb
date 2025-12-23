module Slim
  class LogicLess
    # @api private
    class Context
      def initialize(dict, lookup)
        @scope = [Scope.new(dict, lookup)]
      end

      def [](name)
        scope[name]
      end

      def lambda(name)
        scope.lambda(name) do |*dict|
          if dict.empty?
            yield
          else
            new_scope do
              dict.inject('') do |result, d|
                scope.dict = d
                result << yield
              end
            end
          end
        end
      end

      def section(name)
        if dict = scope[name]
          if !dict.respond_to?(:has_key?) && dict.respond_to?(:each)
            new_scope do
              dict.each do |d|
                scope.dict = d
                yield
              end
            end
          else
            new_scope(dict) { yield }
          end
        end
      end

      def inverted_section(name)
        value = scope[name]
        yield if !value || (value.respond_to?(:empty?) && value.empty?)
      end

      def to_s
        scope.to_s
      end

      private

      class Scope
        attr_reader :lookup
        attr_writer :dict

        def initialize(dict, lookup, parent = nil)
          @dict, @lookup, @parent = dict, lookup, parent
        end

        def lambda(name, &block)
          @lookup.each do |lookup|
            case lookup
            when :method
              return @dict.public_send(name, &block) if @dict.respond_to?(name, false)
            when :symbol
              return @dict[name].call(&block) if has_key?(name)
            when :string
              return @dict[name.to_s].call(&block) if has_key?(name.to_s)
            when :instance_variable
              var_name = "@#{name}"
              return @dict.instance_variable_get(var_name).call(&block) if instance_variable?(var_name)
            end
          end
          @parent.lambda(name) if @parent
        end

        def [](name)
          @lookup.each do |lookup|
            case lookup
            when :method
              return @dict.public_send(name) if @dict.respond_to?(name, false)
            when :symbol
              return @dict[name] if has_key?(name)
            when :string
              return @dict[name.to_s] if has_key?(name.to_s)
            when :instance_variable
              var_name = "@#{name}"
              return @dict.instance_variable_get(var_name) if instance_variable?(var_name)
            end
          end
          @parent[name] if @parent
        end

        def to_s
          @dict.to_s
        end

        private

        def has_key?(name)
          @dict.respond_to?(:has_key?) && @dict.has_key?(name)
        end

        def instance_variable?(name)
          begin
            @dict.instance_variable_defined?(name)
          rescue NameError
            false
          end
        end
      end

      def scope
        @scope.last
      end

      def new_scope(dict = nil)
        @scope << Scope.new(dict, scope.lookup, scope)
        yield
      ensure
        @scope.pop
      end
    end
  end
end
