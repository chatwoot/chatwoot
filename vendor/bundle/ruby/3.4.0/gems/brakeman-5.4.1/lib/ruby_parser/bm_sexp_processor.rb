##
# SexpProcessor provides a uniform interface to process Sexps.
#
# In order to create your own SexpProcessor subclass you'll need
# to call super in the initialize method, then set any of the
# Sexp flags you want to be different from the defaults.
#
# SexpProcessor uses a Sexp's type to determine which process method
# to call in the subclass.  For Sexp <code>s(:lit, 1)</code>
# SexpProcessor will call #process_lit, if it is defined.
#

class Brakeman::SexpProcessor

  VERSION = 'CUSTOM'

  ##
  # Return a stack of contexts. Most recent node is first.

  attr_reader :context

  ##
  # Expected result class

  attr_accessor :expected

  ##
  # A scoped environment to make you happy.

  attr_reader :env

  # Cache process methods per class

  def self.processors
    @processors ||= {}
  end

  ##
  # Creates a new SexpProcessor.  Use super to invoke this
  # initializer from SexpProcessor subclasses, then use the
  # attributes above to customize the functionality of the
  # SexpProcessor

  def initialize
    @expected            = Sexp
    @processors = self.class.processors
    @context    = []
    @current_class = @current_module = @current_method = @visibility = nil

    if @processors.empty?
      public_methods.each do |name|
        if name.to_s.start_with? "process_" then
          @processors[name[8..-1].to_sym] = name.to_sym
        end
      end
    end
  end

  ##
  # Default Sexp processor.  Invokes process_<type> methods matching
  # the Sexp type given.  Performs additional checks as specified by
  # the initializer.

  def process(exp)
    return nil if exp.nil?

    result = nil

    type = exp.first
    raise "Type should be a Symbol, not: #{exp.first.inspect} in #{exp.inspect}" unless Symbol === type

    in_context type do
      # now do a pass with the real processor (or generic)
      meth = @processors[type]
      if meth then
        result = self.send(meth, exp)
      else
        result = self.process_default(exp)
      end
    end
    
    raise SexpTypeError, "Result must be a #{@expected}, was #{result.class}:#{result.inspect}" unless @expected === result
    
    result
  end

  ##
  # Add a scope level to the current env. Eg:
  #
  #   def process_defn exp
  #     name = exp.shift
  #     args = process(exp.shift)
  #     scope do
  #       body = process(exp.shift)
  #       # ...
  #     end
  #   end
  #
  #   env[:x] = 42
  #   scope do
  #     env[:x]       # => 42
  #     env[:y] = 24
  #   end
  #   env[:y]         # => nil

  def scope &block
    env.scope(&block)
  end

  def in_context type
    self.context.unshift type

    yield

    self.context.shift
  end
end
