# frozen_string_literal: true

require 'uber/delegates'

module Representable
  # The Binding provides methods to read/write the fragment for one property.
  #
  # Actually parsing the fragment from the document happens in Binding#read, everything after that is generic.
  class Binding
    class Map < Array
      def call(method, options)
        each do |bin|
          options[:binding] = bin # this is so much faster than options.merge().
          bin.send(method, options)
        end
      end

      # TODO: Merge with Definitions.
      def <<(binding) # can be slow. this is compile time code.
        (existing = find { |bin| bin.name == binding.name }) ? self[index(existing)] = binding : super(binding)
      end
    end

    class FragmentNotFound
    end

    def self.build(definition)
      build_for(definition)
    end

    def initialize(definition)
      @definition       = definition
      @name             = @definition.name
      @getter           = @definition.getter
      @setter           = @definition.setter

      setup_exec_context!
    end

    attr_reader :name, :getter, :setter
    extend Uber::Delegates
    delegates :@definition, :has_default?, :representable?, :array?, :typed?

    # Single entry points for rendering and parsing a property are #compile_fragment
    # and #uncompile_fragment in Mapper.

    module Deprecatable
      # Retrieve value and write fragment to the doc.
      def compile_fragment(options)
        render_pipeline(nil, options).call(nil, options)
      end

      # Parse value from doc and update the model property.
      def uncompile_fragment(options)
        parse_pipeline(options[:doc], options).call(options[:doc], options)
      end
    end
    include Deprecatable

    module EvaluateOption
      def evaluate_option(name, input, options)
        proc = self[name]
        # puts "@@@@@ #{self.inspect}, #{name}...... #{self[name]}"
        proc.call(exec_context: send(:exec_context, options), keyword_arguments: options.merge(user_options: options[:options][:user_options], input: input)) # from Uber::Options::Value. # NOTE: this can also be the Proc object if it's not wrapped by Uber:::Value.
      end
    end
    include EvaluateOption

    def [](name)
      @definition[name]
    end

    def skipable_empty_value?(value)
      value.nil? and !(self[:render_nil])
    end

    def default_for(value)
      return self[:default] if skipable_empty_value?(value)

      value
    end

    attr_accessor :cached_representer

    require 'representable/pipeline_factories'
    include Factories

    private

    def setup_exec_context!
      @exec_context = ->(options) { options[:represented] } unless self[:exec_context]
      @exec_context = ->(_options) { self } if self[:exec_context] == :binding
      @exec_context = ->(options) { options[:decorator] } if self[:exec_context] == :decorator
    end

    def exec_context(options)
      @exec_context.call(options)
    end

    def parse_pipeline(input, options)
      @parse_pipeline ||= pipeline_for(:parse_pipeline, input, options) { Pipeline[*parse_functions] }
    end

    def render_pipeline(input, options)
      @render_pipeline ||= pipeline_for(:render_pipeline, input, options) { Pipeline[*render_functions] }
    end

    # generics for collection bindings.
    module Collection
      def skipable_empty_value?(value)
        # TODO: this can be optimized, again.
        return true if value.nil? && !(self[:render_nil]) # FIXME: test this without the "and"

        true if (self[:render_empty] == false) && value && value.empty? # TODO: change in 2.0, don't render emtpy.
      end
    end
  end

  class DeserializeError < RuntimeError
  end
end
