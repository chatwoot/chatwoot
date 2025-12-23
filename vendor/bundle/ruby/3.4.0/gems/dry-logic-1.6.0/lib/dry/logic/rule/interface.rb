# frozen_string_literal: true

module Dry
  module Logic
    class Rule
      class Interface < ::Module
        SPLAT = ["*rest"].freeze

        attr_reader :arity

        attr_reader :curried

        def initialize(arity, curried)
          super()

          @arity = arity
          @curried = curried

          if !variable_arity? && curried > arity
            raise ArgumentError, "wrong number of arguments (#{curried} for #{arity})"
          end

          define_constructor if curried?

          if constant?
            define_constant_application
          else
            define_application
          end
        end

        def constant? = arity.zero?

        def variable_arity? = arity.negative?

        def curried? = !curried.zero?

        def unapplied
          if variable_arity?
            unapplied = arity.abs - 1 - curried

            if unapplied.negative?
              0
            else
              unapplied
            end
          else
            arity - curried
          end
        end

        def name
          if constant?
            "Constant"
          else
            arity_str =
              if variable_arity?
                "Variable#{arity.abs - 1}Arity"
              else
                "#{arity}Arity"
              end

            curried_str =
              if curried?
                "#{curried}Curried"
              else
                EMPTY_STRING
              end

            "#{arity_str}#{curried_str}"
          end
        end

        def define_constructor
          assignment =
            if curried.equal?(1)
              "@arg0 = @args[0]"
            else
              "#{curried_args.join(", ")} = @args"
            end

          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def initialize(*)  # def initialize(*)
              super            #   super
                               #
              #{assignment}    #   @arg0 = @args[0]
            end                # end
          RUBY
        end

        def define_constant_application
          module_exec do
            def call(*)
              if @predicate[]
                Result::SUCCESS
              else
                Result.new(false, id) { ast }
              end
            end

            def [](*)
              @predicate[]
            end
          end
        end

        def define_application
          splat = variable_arity? ? SPLAT : EMPTY_ARRAY
          parameters = (unapplied_args + splat).join(", ")
          application = "@predicate[#{(curried_args + unapplied_args + splat).join(", ")}]"

          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def call(#{parameters})                          # def call(input0, input1, *rest)
              if #{application}                              #   if @predicate[@arg0, @arg1, input0, input1, *rest]
                Result::SUCCESS                              #     ::Dry::Logic::Result::Success
              else                                           #   else
                Result.new(false, id) { ast(#{parameters}) } #     ::Dry::Logic::Result.new(false, id) { ast(input0, input1, *rest) }
              end                                            #   end
            end                                              # end
                                                             #
            def [](#{parameters})                            # def [](@arg0, @arg1, input0, input1, *rest)
              #{application}                                 #   @predicate[@arg0, @arg1, input0, input1, *rest]
            end                                              # end
          RUBY
        end

        def curried_args
          @curried_args ||= ::Array.new(curried) { "@arg#{_1}" }
        end

        def unapplied_args
          @unapplied_args ||= ::Array.new(unapplied) { "input#{_1}" }
        end
      end
    end
  end
end
