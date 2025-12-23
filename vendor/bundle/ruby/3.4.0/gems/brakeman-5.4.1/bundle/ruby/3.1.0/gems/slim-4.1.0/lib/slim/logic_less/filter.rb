module Slim
  # Handle logic less mode
  # This filter can be activated with the option "logic_less"
  # @api private
  class LogicLess < Filter
    # Default dictionary access order, change it with the option :dictionary_access
    DEFAULT_ACCESS_ORDER = [:symbol, :string, :method, :instance_variable].freeze

    define_options logic_less: true,
                   dictionary: 'self',
                   dictionary_access: DEFAULT_ACCESS_ORDER

    def initialize(opts = {})
      super
      access = [options[:dictionary_access]].flatten.compact
      access.each do |type|
        raise ArgumentError, "Invalid dictionary access #{type.inspect}" unless DEFAULT_ACCESS_ORDER.include?(type)
      end
      raise ArgumentError, 'Option dictionary access is missing' if access.empty?
      @access = access.inspect
    end

    def call(exp)
      if options[:logic_less]
        @context = unique_name
        [:multi,
         [:code, "#{@context} = ::Slim::LogicLess::Context.new(#{options[:dictionary]}, #{@access})"],
         super]
      else
        exp
      end
    end

    # Interpret control blocks as sections or inverted sections
    def on_slim_control(name, content)
      method =
        if name =~ /\A!\s*(.*)/
          name = $1
          'inverted_section'
        else
          'section'
        end
      [:block, "#{@context}.#{method}(#{name.to_sym.inspect}) do", compile(content)]
    end

    def on_slim_output(escape, name, content)
      [:slim, :output, escape, empty_exp?(content) ? access(name) :
       "#{@context}.lambda(#{name.to_sym.inspect}) do", compile(content)]
    end

    def on_slim_attrvalue(escape, value)
      [:slim, :attrvalue, escape, access(value)]
    end

    def on_slim_splat(code)
      [:slim, :splat, access(code)]
    end

    def on_dynamic(code)
      raise Temple::FilterError, 'Embedded code is forbidden in logic less mode'
    end

    def on_code(code)
      raise Temple::FilterError, 'Embedded code is forbidden in logic less mode'
    end

    private

    def access(name)
      case name
      when 'yield'
        'yield'
      when 'self'
        "#{@context}.to_s"
      else
        "#{@context}[#{name.to_sym.inspect}]"
      end
    end
  end
end
