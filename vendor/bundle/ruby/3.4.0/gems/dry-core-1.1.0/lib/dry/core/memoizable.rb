# frozen_string_literal: true

module Dry
  module Core
    module Memoizable
      MEMOIZED_HASH = {}.freeze
      PARAM_PLACEHOLDERS = %i[* ** &].freeze

      module ClassInterface
        module Base
          def memoize(*names)
            prepend(Memoizer.new(self, names))
          end

          def inherited(base)
            super

            memoizer = base.ancestors.find { _1.is_a?(Memoizer) }
            base.prepend(memoizer.dup) if memoizer
          end
        end

        module BasicObject
          include Base

          def new(*, **)
            obj = super
            obj.instance_eval { @__memoized__ = MEMOIZED_HASH.dup }
            obj
          end
        end

        module Object
          include Base

          def new(*, **)
            obj = super
            obj.instance_variable_set(:@__memoized__, MEMOIZED_HASH.dup)
            obj
          end
        end
      end

      def self.included(klass)
        super

        if klass <= Object
          klass.extend(ClassInterface::Object)
        else
          klass.extend(ClassInterface::BasicObject)
        end
      end

      # @api private
      class Memoizer < ::Module
        KERNEL = {
          singleton: ::Kernel.instance_method(:singleton_class),
          ivar_set: ::Kernel.instance_method(:instance_variable_set),
          frozen: ::Kernel.instance_method(:frozen?)
        }.freeze

        # @api private
        def initialize(klass, names)
          super()
          names.each do |name|
            define_memoizable(
              method: klass.instance_method(name)
            )
          end
        end

        private

        # @api private
        # rubocop:disable Metrics/AbcSize
        def define_memoizable(method:)
          parameters = method.parameters
          mod = self
          kernel = KERNEL

          if parameters.empty?
            key = "#{__id__}:#{method.name}".hash.abs

            define_method(method.name) do
              value = super()

              if kernel[:frozen].bind_call(self)
                # It's not possible to modify singleton classes
                # of frozen objects
                mod.remove_method(method.name)
                mod.module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
                  def #{method.name}                          # def slow_calc
                    cached = @__memoized__[#{key}]            #   cached = @__memoized__[12345678]
                                                              #
                    if cached || @__memoized__.key?(#{key})   #   if cached || @__memoized__.key?(12345678)
                      cached                                  #     cached
                    else                                      #   else
                      @__memoized__[#{key}] = super           #     @__memoized__[12345678] = super
                    end                                       #   end
                  end                                         # end
                RUBY
              else
                # We make an attr_reader for computed value.
                # Readers are "special-cased" in ruby so such
                # access will be the fastest way, faster than you'd
                # expect :)
                attr_name = :"__memozed_#{key}__"
                ivar_name = :"@#{attr_name}"
                kernel[:ivar_set].bind_call(self, ivar_name, value)
                eigenclass = kernel[:singleton].bind_call(self)
                eigenclass.attr_reader(attr_name)
                eigenclass.alias_method(method.name, attr_name)
                eigenclass.remove_method(attr_name)
              end

              value
            end
          else
            mapping = parameters.to_h { |k, v = nil| [k, v] }
            params, binds = declaration(parameters, mapping)
            last_param = parameters.last

            if last_param[0].eql?(:block) && !last_param[1].eql?(:&)
              Deprecations.warn(<<~WARN)
                Memoization for block-accepting methods isn't safe.
                Every call creates a new block instance bloating cached results.
                In the future, blocks will still be allowed but won't participate in
                cache key calculation.
              WARN
            end

            module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
              def #{method.name}(#{params.join(", ")})                 # def slow_calc(arg1, arg2, arg3)
                key = [:"#{method.name}", #{binds.join(", ")}].hash    #   key = [:slow_calc, arg1, arg2, arg3].hash
                                                                       #
                if @__memoized__.key?(key)                             #   if @__memoized__.key?(key)
                  @__memoized__[key]                                   #     @__memoized__[key]
                else                                                   #   else
                  @__memoized__[key] = super                           #     @__memoized__[key] = super
                end                                                    #   end
              end                                                      # end
            RUBY

          end
        end

        # rubocop:enable Metrics/AbcSize
        # @api private
        def declaration(definition, lookup)
          params = []
          binds = []
          defined = {}

          definition.each do |type, name|
            mapped_type = map_bind_type(type, name, lookup, defined) do
              raise ::NotImplementedError, "type: #{type}, name: #{name}"
            end

            if mapped_type
              defined[mapped_type] = true
              bind = name_from_param(name) || make_bind_name(binds.size)

              binds << bind
              params << param(bind, mapped_type)
            end
          end

          [params, binds]
        end

        # @api private
        def name_from_param(name)
          if PARAM_PLACEHOLDERS.include?(name)
            nil
          else
            name
          end
        end

        # @api private
        def make_bind_name(idx)
          :"__lv_#{idx}__"
        end

        # @api private
        def map_bind_type(type, name, original_params, defined_types) # rubocop:disable Metrics/PerceivedComplexity
          case type
          when :req
            :reqular
          when :rest, :keyreq, :keyrest
            type
          when :block
            if name.eql?(:&)
              # most likely this is a case of delegation
              # rather than actual block
              nil
            else
              type
            end
          when :opt
            if original_params.key?(:rest) || defined_types[:rest]
              nil
            else
              :rest
            end
          when :key
            if original_params.key?(:keyrest) || defined_types[:keyrest]
              nil
            else
              :keyrest
            end
          else
            yield
          end
        end

        # @api private
        def param(name, type)
          case type
          when :reqular
            name
          when :rest
            "*#{name}"
          when :keyreq
            "#{name}:"
          when :keyrest
            "**#{name}"
          when :block
            "&#{name}"
          end
        end
      end
    end
  end
end
