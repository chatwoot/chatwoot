require 'declarative/definitions'

module Representable
  autoload :Pipeline, "representable/pipeline"
  autoload :Populator, "representable/populator"
  autoload :Option, "representable/option"

  # Created at class compile time. Keeps configuration options for one property.
  class Definition < ::Declarative::Definitions::Definition

    def initialize(sym, options={}, &block)
      options[:extend] = options[:nested] if options[:nested]

      super

      # defaults:
      options[:parse_filter]  = Pipeline[*options[:parse_filter]]
      options[:render_filter] = Pipeline[*options[:render_filter]]

      setup!(options, &block)
    end

    def name
      self[:name]
    end
    alias_method :getter, :name

    def merge!(options, &block)
      options = options.clone

      options[:parse_filter]  = @options[:parse_filter].push(*options[:parse_filter])
      options[:render_filter] = @options[:render_filter].push(*options[:render_filter])

      setup!(options, &block) # FIXME: this doesn't yield :as etc.
      self
    end

    def delete!(name)
      @runtime_options.delete(name)
      @options.delete(name)
      self
    end

    def [](name)
      # return nil if name==:extend && self[:nested].nil?
      # return Uber::Options::Value.new(self[:nested]) if name==:extend
      @runtime_options[name]
    end

    def setter
      :"#{name}="
    end

    def typed? # TODO: remove.
      self[:class] or self[:extend] or self[:instance]
    end

    def representable?
      return if self[:representable] == false

      self[:representable] or typed?
    end

    def array?
      self[:collection]
    end

    def hash?
      self[:hash]
    end

    def has_default?
      @options.has_key?(:default)
    end

    def representer_module
      @options[:extend]
    end

    def create_binding(*args)
      self[:binding].call(self, *args)
    end

    def inspect
      state = (instance_variables-[:@runtime_options, :@name]).collect { |ivar| "#{ivar}=#{instance_variable_get(ivar)}" }
      "#<Representable::Definition ==>#{name} #{state.join(" ")}>"
    end

  private
    def setup!(options, &block)
      handle_extend!(options)
      handle_as!(options)

      # DISCUSS: we could call more macros here (e.g. for :nested).
      Representable::Populator.apply!(options)

      yield options if block_given?
      @options.merge!(options)

      runtime_options!(@options)
    end

    # wrapping dynamic options in Value does save runtime, as this is used very frequently (and totally unnecessary to wrap an option
    # at runtime, its value never changes).
    def runtime_options!(options)
      @runtime_options = {}

      for name, value in options
        value = ::Representable::Option(value) if dynamic_options.include?(name)
        @runtime_options[name] = value
      end
    end

    def dynamic_options
      [:as, :getter, :setter, :class, :instance, :reader, :writer, :extend, :prepare, :if, :deserialize, :serialize, :skip_parse, :skip_render]
    end

    def handle_extend!(options)
      mod = options.delete(:extend) || options.delete(:decorator) and options[:extend] = mod
    end

    def handle_as!(options)
      options[:as] = options[:as].to_s if options[:as].is_a?(Symbol) # Allow symbols for as:
    end
  end
end
