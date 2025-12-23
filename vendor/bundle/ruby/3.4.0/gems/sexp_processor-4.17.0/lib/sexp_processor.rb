$TESTING = false unless defined? $TESTING

require "sexp"

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
# You can also specify a default method to call for any Sexp types
# without a process_<type> method or use the default processor provided to
# skip over them.
#
# Here is a simple example:
#
#   class MyProcessor < SexpProcessor
#     def initialize
#       super
#       self.strict = false
#     end
#
#     def process_lit(exp)
#       val = exp.shift
#       return val
#     end
#   end

class SexpProcessor

  # duh
  VERSION = "4.17.0"

  ##
  # Automatically shifts off the Sexp type before handing the
  # Sexp to process_<type>

  attr_accessor :auto_shift_type

  ##
  # Return a stack of contexts. Most recent node is first.

  attr_reader :context

  ##
  # A Hash of Sexp types and Regexp.
  #
  # Print a debug message if the Sexp type matches the Hash key
  # and the Sexp's #inspect output matches the Regexp.

  attr_accessor :debug

  ##
  # A default method to call if a process_<type> method is not found
  # for the Sexp type.

  attr_accessor :default_method

  ##
  # Expected result class

  attr_accessor :expected

  ##
  # Raise an exception if the Sexp is not empty after processing

  attr_accessor :require_empty

  ##
  # Raise an exception if no process_<type> method is found for a Sexp.

  attr_accessor :strict

  ##
  # An array that specifies node types that are unsupported by this
  # processor. SexpProcessor will raise UnsupportedNodeError if you try
  # to process one of those node types.

  attr_accessor :unsupported

  ##
  # Emit a warning when the method in #default_method is called.

  attr_accessor :warn_on_default

  ##
  # A scoped environment to make you happy.

  attr_reader :env

  ##
  # Expand an array of directories into a flattened array of paths, eg:
  #
  #     MyProcessor.run MyProcessor.expand_dirs_to_files ARGV

  def self.expand_dirs_to_files *dirs
    extensions = %w[rb rake]

    dirs.flatten.map { |p|
      if File.directory? p then
        Dir[File.join(p, "**", "*.{#{extensions.join ","}}")]
      else
        p
      end
    }.flatten.sort
  end

  ##
  # Cache processor methods per class.

  def self.processors
    @processors ||= {}
  end

  ##
  # Cache rewiter methods per class.

  def self.rewriters
    @rewriters ||= {}
  end

  ##
  # Creates a new SexpProcessor.  Use super to invoke this
  # initializer from SexpProcessor subclasses, then use the
  # attributes above to customize the functionality of the
  # SexpProcessor

  def initialize
    @default_method      = nil
    @warn_on_default     = true
    @auto_shift_type     = false
    @strict              = false
    @unsupported         = [:alloca, :cfunc, :cref, :ifunc, :last, :memo,
                            :newline, :opt_n, :method]
    @unsupported_checked = false
    @debug               = {}
    @expected            = Sexp
    @require_empty       = true
    @exceptions          = {}

    # we do this on an instance basis so we can subclass it for
    # different processors.
    @processors = self.class.processors
    @rewriters  = self.class.rewriters
    @context    = []

    if @processors.empty?
      public_methods.each do |name|
        case name
        when /^process_(.*)/ then
          @processors[$1.to_sym] = name.to_sym
        when /^rewrite_(.*)/ then
          @rewriters[$1.to_sym]  = name.to_sym
        end
      end
    end
  end

  ##
  # Raise if +exp+ is not empty.

  def assert_empty meth, exp, exp_orig
    unless exp.empty? then
      msg = "exp not empty after #{self.class}.#{meth} on #{exp.inspect}"
      msg += " from #{exp_orig.inspect}" if $DEBUG
      raise NotEmptyError, msg
    end
  end

  ##
  # Rewrite +exp+ using rewrite_* method for +exp+'s sexp_type, if one
  # exists.

  def rewrite exp
    type = exp.sexp_type

    comments = exp.comments

    if @debug.key? type then
      str = exp.inspect
      puts "// DEBUG (original ): #{str}" if str =~ @debug[type]
    end

    in_context type do
      exp = exp.map { |sub| Array === sub ? rewrite(sub) : sub }
    end

    loop do
      meth = @rewriters[type]
      exp  = self.send(meth, exp) if meth
      break unless Sexp === exp

      if @debug.key? type then
        str = exp.inspect
        puts "// DEBUG (rewritten): #{str}" if str =~ @debug[type]
      end

      old_type, type = type, exp.sexp_type
      break if old_type == type
    end

    exp.comments = comments

    exp
  end

  ##
  # Default Sexp processor.  Invokes process_<type> methods matching
  # the Sexp type given.  Performs additional checks as specified by
  # the initializer.

  def process exp
    return nil if exp.nil?

    unless Sexp === exp then
      raise SexpTypeError, "exp must be a Sexp, was #{exp.class}:#{exp.inspect}"
    end

    if self.context.empty? then
      p :rewriting unless debug.empty?
      exp = self.rewrite(exp)
      p :done_rewriting unless debug.empty?
    end

    unless @unsupported_checked then
      m = public_methods.grep(/^process_/) { |o| o.to_s.sub(/^process_/, "").to_sym }
      supported = m - (m - @unsupported)

      raise UnsupportedNodeError, "#{supported.inspect} shouldn't be in @unsupported" unless supported.empty?

      @unsupported_checked = true
    end

    result = self.expected.new

    type = exp.sexp_type
    raise "type should be a Symbol, not: #{exp.first.inspect}" unless
      Symbol === type

    in_context type do
      if @debug.key? type then
        str = exp.inspect
        puts "// DEBUG:(original ): #{str}" if str =~ @debug[type]
      end

      exp_orig = nil
      exp_orig = exp.deep_clone if $DEBUG or
        @debug.key? type or @exceptions.key?(type)

      raise UnsupportedNodeError, "'#{type}' is not a supported node type" if
        @unsupported.include? type

      # now do a pass with the real processor (or generic)
      meth = @processors[type] || @default_method
      if meth then

        if @warn_on_default and meth == @default_method then
          warn "WARNING: Using default method #{meth} for #{type}"
        end

        exp = exp.sexp_body if @auto_shift_type and meth != @default_method # HACK

        result = error_handler(type, exp_orig) {
          self.send meth, exp
        }

        if @debug.key? type then
          str = exp.inspect
          puts "// DEBUG (processed): #{str}" if str =~ @debug[type]
        end

        raise SexpTypeError, "Result of #{type} must be a #{@expected}, was #{result.class}:#{result.inspect}" unless
          @expected === result

        self.assert_empty(meth, exp, exp_orig) if @require_empty
      else
        unless @strict then
          until exp.empty? do
            sub_exp, *exp = exp # HACK
            sub_result = nil
            if Array === sub_exp then
              sub_result = error_handler(type, exp_orig) do
                process(sub_exp)
              end
              raise "Result is a bad type" unless Array === sub_exp
              raise "Result does not have a type in front: #{sub_exp.inspect}" unless
                Symbol === sub_exp.sexp_type unless
                sub_exp.empty?
            else
              sub_result = sub_exp
            end
            # result << sub_result
            result = result.class.new(*result, sub_result) # HACK
          end

          # NOTE: this is costly, but we are in the generic processor
          # so we shouldn't hit it too much with RubyToC stuff at least.
          result.c_type ||= exp.c_type if Sexp === exp and exp.respond_to?(:c_type)
        else
          msg = "Bug! Unknown node-type #{type.inspect} to #{self.class}"
          msg += " in #{exp_orig.inspect} from #{caller.inspect}" if $DEBUG
          raise UnknownNodeError, msg
        end
      end
    end

    result
  end

  ##
  # Raises unless the Sexp type for +list+ matches +typ+

  def assert_type list, typ
    raise SexpTypeError, "Expected type #{typ.inspect} in #{list.inspect}" if
      not Array === list or list.sexp_type != typ
  end

  def error_handler type, exp = nil # :nodoc:
    yield
  rescue StandardError => err
    return @exceptions[type].call self, exp, err if @exceptions.key? type

    warn "#{err.class} Exception thrown while processing #{type} for sexp #{exp.inspect} #{caller.inspect}" if
      $DEBUG

    raise
  end

  ##
  # Registers an error handler for +node+

  def on_error_in node_type, &block
    @exceptions[node_type] = block
  end

  ##
  # A fairly generic processor for a dummy node. Dummy nodes are used
  # when your processor is doing a complicated rewrite that replaces
  # the current sexp with multiple sexps.
  #
  # Bogus Example:
  #
  #   def process_something(exp)
  #     return s(:dummy, process(exp), s(:extra, 42))
  #   end

  def process_dummy exp
    result = @expected.new(:dummy) rescue @expected.new
    result << self.process(exp.shift) until exp.empty?
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

  ##
  # Track a stack of contexts that the processor is in, pushing on
  # +type+ yielding, and then removing the context from the stack.

  def in_context type
    self.context.unshift type

    yield

  ensure
    self.context.shift
  end

  ##
  # I really hate this here, but I hate subdirs in my lib dir more...
  # I guess it is kinda like shaving... I'll split this out when it
  # itches too much...

  class Environment
    def initialize #:nodoc:
      @env = []
      @env.unshift({})
    end

    ##
    # Flatten out all scopes and return all key/value pairs.

    def all
      @env.reverse.inject { |env, scope| env.merge scope }
    end

    ##
    # Return the current number of scopes.

    def depth
      @env.length
    end

    # TODO: depth_of

    ##
    # Get +name+ from env at whatever scope it is defined in, or return nil.

    def [] name
      hash = @env.find { |closure| closure.key? name }
      hash[name] if hash
    end

    ##
    # If +name+ exists in the env, set it to +val+ in whatever scope
    # it is in. If it doesn't exist, set +name+ to +val+ in the
    # current scope.

    def []= name, val
      hash = @env.find { |closure| closure.key? name } || current
      hash[name] = val
    end

    ##
    # Get the current/top environment.

    def current
      @env.first
    end

    ##
    # Create a new scope and yield to the block passed.

    def scope
      @env.unshift({})
      begin
        yield
      ensure
        @env.shift
        raise "You went too far unextending env" if @env.empty?
      end
    end
  end
end

##
# A simple subclass of SexpProcessor that defines a pattern I commonly
# use: non-mutative and strict process that return assorted values;
# AKA, an interpreter.

class SexpInterpreter < SexpProcessor
  def initialize #:nodoc:
    super

    self.expected        = Object
    self.require_empty   = false
    self.strict          = true
  end
end

##
# A simple subclass of SexpProcessor that tracks method and class
# stacks for you. Use #method_name, #klass_name, or #signature to
# refer to where you're at in processing. If you have to subclass
# process_(class|module|defn|defs) you _must_ call super.

class MethodBasedSexpProcessor < SexpProcessor
  @@no_class  = :main
  @@no_method = :none

  ##
  # A stack of the classes/modules that are being processed

  attr_reader :class_stack

  ##
  # A stack of the methods that are being processed. You'd think it'd
  # only ever be 1 deep, but you'd be wrong. People do terrible things
  # in/to ruby.

  attr_reader :method_stack

  ##
  # A stack of the singleton classes that are being processed.

  attr_reader :sclass

  ##
  # A lookup table of all the method locations that have been
  # processed so far.

  attr_reader :method_locations

  def initialize #:nodoc:
    super
    @sclass              = []
    @class_stack         = []
    @method_stack        = []
    @method_locations    = {}
    self.require_empty   = false
  end

  ##
  # Adds name to the class stack, for the duration of the block

  def in_klass name
    if Sexp === name then
      name = case name.sexp_type
             when :colon2 then
               name = name.flatten
               name.delete :const
               name.delete :colon2
               name.join("::")
             when :colon3 then
               name.last.to_s
             else
               raise "unknown type #{name.inspect}"
             end
    end

    @class_stack.unshift name

    with_new_method_stack do
      yield
    end
  ensure
    @class_stack.shift
  end

  ##
  # Adds name to the method stack, for the duration of the block

  def in_method name, file, line, line_max = nil
    method_name = Regexp === name ? name.inspect : name.to_s
    @method_stack.unshift method_name
    line_max = "-#{line_max}" if line_max
    @method_locations[signature] = "#{file}:#{line}#{line_max}"
    yield
  ensure
    @method_stack.shift
  end

  ##
  # Tracks whether we're in a singleton class or not. Doesn't track
  # actual receiver.

  def in_sklass
    @sclass.push true

    with_new_method_stack do
      yield
    end
  ensure
    @sclass.pop
  end

  ##
  # Returns the first class in the list, or @@no_class if there are
  # none.

  def klass_name
    name = @class_stack.first

    raise "you shouldn't see me" if Sexp === name

    if @class_stack.any?
      @class_stack.reverse.join("::").sub(/\([^\)]+\)$/, "")
    else
      @@no_class
    end
  end

  ##
  # Returns the first method in the list, or "#none" if there are
  # none.

  def method_name
    m = @method_stack.first || @@no_method
    m = "##{m}" unless m =~ /::/
    m
  end

  ##
  # Process a class node until empty. Tracks all nesting. If you have
  # to subclass and override this method, you can call super with a
  # block.

  def process_class exp
    exp.shift unless auto_shift_type # node type
    in_klass exp.shift do
      if block_given? then
        yield
      else
        process_until_empty exp
      end
    end
    s()
  end

  ##
  # Process a method node until empty. Tracks your location. If you
  # have to subclass and override this method, you can clall super
  # with a block.

  def process_defn exp
    exp.shift unless auto_shift_type # node type
    name = @sclass.empty? ? exp.shift : "::#{exp.shift}"

    in_method name, exp.file, exp.line, exp.line_max do
      if block_given? then
        yield
      else
        process_until_empty exp
      end
    end
    s()
  end

  ##
  # Process a singleton method node until empty. Tracks your location.
  # If you have to subclass and override this method, you can clall
  # super with a block.

  def process_defs exp
    exp.shift unless auto_shift_type # node type
    process exp.shift # recv
    in_method "::#{exp.shift}", exp.file, exp.line, exp.line_max do
      if block_given? then
        yield
      else
        process_until_empty exp
      end
    end
    s()
  end

  ##
  # Process a module node until empty. Tracks all nesting. If you have
  # to subclass and override this method, you can clall super with a
  # block.

  def process_module exp
    exp.shift unless auto_shift_type # node type
    in_klass exp.shift do
      if block_given? then
        yield
      else
        process_until_empty exp
      end
    end
    s()
  end

  ##
  # Process a singleton class node until empty. Tracks all nesting. If
  # you have to subclass and override this method, you can clall super
  # with a block.

  def process_sclass exp
    exp.shift unless auto_shift_type # node type
    in_sklass do
      if block_given? then
        yield
      else
        process_until_empty exp
      end
    end
    s()
  end

  ##
  # Process each element of #exp in turn.

  def process_until_empty exp
    until exp.empty?
      sexp = exp.shift
      process sexp if Sexp === sexp
    end
  end

  ##
  # Returns the method signature for the current method.

  def signature
    "#{klass_name}#{method_name}"
  end

  ##
  # Reset the method stack for the duration of the block. Used for
  # class scoping.

  def with_new_method_stack
    old_method_stack, @method_stack = @method_stack, []

    yield
  ensure
    @method_stack = old_method_stack
  end
end

class Object # :nodoc:

  ##
  # deep_clone is the usual Marshalling hack to make a deep copy.
  # It is rather slow, so use it sparingly. Helps with debugging
  # SexpProcessors since you usually shift off sexps.

  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

##
# SexpProcessor base exception class.

class SexpProcessorError < StandardError; end

##
# Raised by SexpProcessor if it sees a node type listed in its
# unsupported list.

class UnsupportedNodeError < SexpProcessorError; end

##
# Raised by SexpProcessor if it is in strict mode and sees a node for
# which there is no processor available.

class UnknownNodeError < SexpProcessorError; end

##
# Raised by SexpProcessor if a processor did not process every node in
# a sexp and @require_empty is true.

class NotEmptyError < SexpProcessorError; end

##
# Raised if assert_type encounters an unexpected sexp type.

class SexpTypeError < SexpProcessorError; end
