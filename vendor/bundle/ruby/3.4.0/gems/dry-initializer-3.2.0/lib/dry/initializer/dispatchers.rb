# frozen_string_literal: true

# The module is responsible for __normalizing__ arguments
# of `.param` and `.option`.
#
# What the module does is convert the source list of arguments
# into the standard set of options:
# - `:option`   -- whether an argument is an option (or param)
# - `:source`   -- the name of source option
# - `:target`   -- the target name of the reader
# - `:reader`   -- if the reader's privacy (:public, :protected, :private, nil)
# - `:ivar`     -- the target name of the variable
# - `:type`     -- the callable coercer of the source value
# - `:optional` -- if the argument is optional
# - `:default`  -- the proc returning the default value of the source value
# - `:null`     -- the value to be set to unassigned optional argument
#
# It is this set is used to build [Dry::Initializer::Definition].
#
# @example
#    # from `option :foo, [], as: :bar, optional: :true
#    input = { name: :foo, as: :bar, type: [], optional: true }
#
#    Dry::Initializer::Dispatcher.call(input)
#    # => {
#    #      source:   "foo",
#    #      target:   "bar",
#    #      reader:   :public,
#    #      ivar:     "@bar",
#    #      type:  ->(v) { Array(v) } }, # simplified for brevity
#    #      optional: true,
#    #      default:  -> { Dry::Initializer::UNDEFINED },
#    #    }
#
# # Settings
#
# The module uses global setting `null` to define what value
# should be set to variables that kept unassigned. By default it
# uses `Dry::Initializer::UNDEFINED`
#
# # Syntax Extensions
#
# The module supports syntax extensions. You can add any number
# of custom dispatchers __on top__ of the stack of default dispatchers.
# Every dispatcher should be a callable object that takes
# the source set of options and converts it to another set of options.
#
# @example Add special dispatcher
#
#   # Define a dispatcher for key :integer
#   dispatcher = proc do |integer: false, **opts|
#     opts.merge(type: proc(&:to_i)) if integer
#   end
#
#   # Register a dispatcher
#   Dry::Initializer::Dispatchers << dispatcher
#
#   # Now you can use option `integer: true` instead of `type: proc(&:to_i)`
#   class Foo
#     extend Dry::Initializer
#     param :id, integer: true
#   end
#
module Dry
  module Initializer
    module Dispatchers
      extend self

      # @!attribute [rw] null Defines a value to be set to unassigned attributes
      # @return [Object]
      attr_accessor :null

      #
      # Registers a new dispatcher
      #
      # @param [#call] dispatcher
      # @return [self] itself
      #
      def <<(dispatcher)
        @pipeline = [dispatcher] + pipeline
        self
      end

      #
      # Normalizes the source set of options
      #
      # @param [Hash<Symbol, Object>] options
      # @return [Hash<Symbol, Objct>] normalized set of options
      #
      def call(**options)
        options = {null:, **options}
        pipeline.reduce(options) { |opts, dispatcher| dispatcher.call(**opts) }
      end

      private

      require_relative "dispatchers/build_nested_type"
      require_relative "dispatchers/check_type"
      require_relative "dispatchers/prepare_default"
      require_relative "dispatchers/prepare_ivar"
      require_relative "dispatchers/prepare_optional"
      require_relative "dispatchers/prepare_reader"
      require_relative "dispatchers/prepare_source"
      require_relative "dispatchers/prepare_target"
      require_relative "dispatchers/unwrap_type"
      require_relative "dispatchers/wrap_type"

      def pipeline
        @pipeline ||= [
          PrepareSource, PrepareTarget, PrepareIvar, PrepareReader,
          PrepareDefault, PrepareOptional,
          UnwrapType, CheckType, BuildNestedType, WrapType
        ]
      end
    end
  end
end
