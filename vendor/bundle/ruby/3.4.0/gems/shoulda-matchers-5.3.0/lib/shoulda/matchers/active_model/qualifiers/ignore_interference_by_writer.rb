module Shoulda
  module Matchers
    module ActiveModel
      module Qualifiers
        # @private
        class IgnoreInterferenceByWriter
          attr_reader :setting, :condition

          def initialize(argument = :always)
            set(argument)
            @changed = false
          end

          def set(argument)
            if argument.is_a?(self.class)
              @setting = argument.setting
              @condition = argument.condition
            else
              case argument
              when true, :always
                @setting = :always
              when false, :never
                @setting = :never
              else
                @setting = :sometimes

                if argument.is_a?(Hash)
                  @condition = argument.fetch(:when)
                else
                  raise invalid_argument_error(argument)
                end
              end
            end

            @changed = true

            self
          rescue KeyError
            raise invalid_argument_error(argument)
          end

          def default_to(argument)
            temporary_ignore_interference_by_writer =
              IgnoreInterferenceByWriter.new(argument)

            unless changed?
              @setting = temporary_ignore_interference_by_writer.setting
              @condition = temporary_ignore_interference_by_writer.condition
            end

            self
          end

          def considering?(value)
            case setting
            when :always then true
            when :never then false
            else condition_matches?(value)
            end
          end

          def always?
            setting == :always
          end

          def never?
            setting == :never
          end

          def changed?
            @changed
          end

          private

          def invalid_argument_error(invalid_argument)
            ArgumentError.new(<<-ERROR)
Unknown argument: #{invalid_argument.inspect}.

ignoring_interference_by_writer takes one of three arguments:

* A symbol, either :never or :always.
* A boolean, either true (which means always) or false (which means
  never).
* A hash with a single key, :when, and a single value, which is either
  the name of a method or a Proc.
            ERROR
          end

          def condition_matches?(value)
            if condition.respond_to?(:call)
              condition.call(value)
            else
              value.public_send(condition)
            end
          end
        end
      end
    end
  end
end
