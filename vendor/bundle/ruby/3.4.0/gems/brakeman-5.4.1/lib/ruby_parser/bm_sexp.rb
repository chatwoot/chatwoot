#Sexp changes from ruby_parser
#and some changes for caching hash value and tracking 'original' line number
#of a Sexp.
class Sexp
  attr_accessor :original_line, :or_depth
  ASSIGNMENT_BOOL = [:gasgn, :iasgn, :lasgn, :cvdecl, :cvasgn, :cdecl, :or, :and, :colon2, :op_asgn_or]
  CALLS = [:call, :attrasgn, :safe_call, :safe_attrasgn]

  def method_missing name, *args
    #Brakeman does not use this functionality,
    #so overriding it to raise a NoMethodError.
    #
    #The original functionality calls find_node and optionally
    #deletes the node if found.
    #
    #Defining a method named "return" seems like a bad idea, so we have to
    #check for it here instead
    if name == :return
      find_node name, *args
    else
      raise NoMethodError.new("No method '#{name}' for Sexp", name, args)
    end
  end

  #Create clone of Sexp and nested Sexps but not their non-Sexp contents.
  #If a line number is provided, also sets line/original_line on all Sexps.
  def deep_clone line = nil
    s = Sexp.new

    self.each do |e|
      if e.is_a? Sexp
        s << e.deep_clone(line)
      else
        s << e
      end
    end

    if line
      s.original_line = self.original_line || self.line
      s.line(line)
    else
      s.original_line = self.original_line
      s.line(self.line) if self.line
    end

    s
  end

  def paren
    @paren ||= false
  end

  def value
    raise WrongSexpError, "Sexp#value called on multi-item Sexp: `#{self.inspect}`" if size > 2
    self[1]
  end

  def value= exp
    raise WrongSexpError, "Sexp#value= called on multi-item Sexp: `#{self.inspect}`" if size > 2
    @my_hash_value = nil
    self[1] = exp
  end

  def second
    self[1]
  end

  def to_sym
    self.value.to_sym
  end

  def node_type= type
    @my_hash_value = nil
    self[0] = type
  end

  #Join self and exp into an :or Sexp.
  #Sets or_depth.
  #Used for combining "branched" values in AliasProcessor.
  def combine exp, line = nil
    combined = Sexp.new(:or, self, exp).line(line || -2)

    combined.or_depth = [self.or_depth, exp.or_depth].compact.reduce(0, :+) + 1

    combined
  end

  alias :node_type :sexp_type
  alias :values :sexp_body # TODO: retire

  alias :old_push :<<
  alias :old_compact :compact
  alias :old_fara :find_and_replace_all
  alias :old_find_node :find_node

  def << arg
    @my_hash_value = nil
    old_push arg
  end

  def hash
    #There still seems to be some instances in which the hash of the
    #Sexp changes, but I have not found what method call is doing it.
    #Of course, Sexp is subclasses from Array, so who knows what might
    #be going on.
    @my_hash_value ||= super
  end

  def compact
    @my_hash_value = nil
    old_compact
  end

  def find_and_replace_all *args
    @my_hash_value = nil
    old_fara(*args)
  end

  def find_node *args
    @my_hash_value = nil
    old_find_node(*args)
  end

  #Raise a WrongSexpError if the nodes type does not match one of the expected
  #types.
  def expect *types
    unless types.include? self.node_type
      raise WrongSexpError, "Expected #{types.join ' or '} but given #{self.inspect}", caller[1..-1]
    end
  end

  #Returns target of a method call:
  #
  #s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1)))
  #         ^-----------target-----------^
  def target
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    self[1]
  end

  #Sets the target of a method call:
  def target= exp
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    @my_hash_value = nil
    self[1] = exp
  end

  #Returns method of a method call:
  #
  #s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1)))
  #                        ^- method
  def method
    expect :call, :attrasgn, :safe_call, :safe_attrasgn, :super, :zsuper, :result

    case self.node_type
    when :call, :attrasgn, :safe_call, :safe_attrasgn
      self[2]
    when :super, :zsuper
      :super
    when :result
      self.last
    end
  end

  def method= name
    expect :call, :safe_call

    self[2] = name
  end

  #Sets the arglist in a method call.
  def arglist= exp
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    @my_hash_value = nil
    start_index = 3

    if exp.is_a? Sexp and exp.node_type == :arglist
      exp = exp.sexp_body
    end

    exp.each_with_index do |e, i|
      self[start_index + i] = e
    end
  end

  def set_args *exp
    self.arglist = exp
  end

  #Returns arglist for method call. This differs from Sexp#args, as Sexp#args
  #does not return a 'real' Sexp (it does not have a node type) but
  #Sexp#arglist returns a s(:arglist, ...)
  #
  #    s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1), s(:lit, 2)))
  #                                                 ^------------ arglist ------------^
  def arglist
    expect :call, :attrasgn, :safe_call, :safe_attrasgn, :super, :zsuper

    case self.node_type
    when :call, :attrasgn, :safe_call, :safe_attrasgn
      self.sexp_body(3).unshift :arglist
    when :super, :zsuper
      if self[1]
        self.sexp_body.unshift :arglist
      else
        Sexp.new(:arglist)
      end
    end
  end

  #Returns arguments of a method call. This will be an 'untyped' Sexp.
  #
  #    s(:call, s(:call, nil, :x, s(:arglist)), :y, s(:arglist, s(:lit, 1), s(:lit, 2)))
  #                                                             ^--------args--------^
  def args
    expect :call, :attrasgn, :safe_call, :safe_attrasgn, :super, :zsuper

    case self.node_type
    when :call, :attrasgn, :safe_call, :safe_attrasgn
      if self[3]
        self.sexp_body(3)
      else
        Sexp.new
      end
    when :super, :zsuper
      if self[1]
        self.sexp_body
      else
        Sexp.new
      end
    end
  end

  def each_arg replace = false
    expect :call, :attrasgn, :safe_call, :safe_attrasgn, :super, :zsuper
    range = nil

    case self.node_type
    when :call, :attrasgn, :safe_call, :safe_attrasgn
      if self[3]
        range = (3...self.length)
      end
    when :super, :zsuper
      if self[1]
        range = (1...self.length)
      end
    end

    if range
      range.each do |i|
        res = yield self[i]
        self[i] = res if replace
      end
    end

    self
  end

  def each_arg! &block
    @my_hash_value = nil
    self.each_arg true, &block
  end

  #Returns first argument of a method call.
  def first_arg
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    self[3]
  end

  #Sets first argument of a method call.
  def first_arg= exp
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    @my_hash_value = nil
    self[3] = exp
  end

  #Returns second argument of a method call.
  def second_arg
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    self[4]
  end

  #Sets second argument of a method call.
  def second_arg= exp
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    @my_hash_value = nil
    self[4] = exp
  end

  def third_arg
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    self[5]
  end

  def third_arg= exp
    expect :call, :attrasgn, :safe_call, :safe_attrasgn
    @my_hash_value = nil
    self[5] = exp
  end

  def last_arg
    expect :call, :attrasgn, :safe_call, :safe_attrasgn

    if self[3]
      self[-1]
    else
      nil
    end
  end

  def call_chain
    expect :call, :attrasgn, :safe_call, :safe_attrasgn

    chain = []
    call = self

    while call.class == Sexp and CALLS.include? call.first 
      chain << call.method
      call = call.target
    end

    chain.reverse!
    chain
  end

  #Returns condition of an if expression:
  #
  #    s(:if,
  #     s(:lvar, :condition), <-- condition
  #     s(:lvar, :then_val),
  #     s(:lvar, :else_val)))
  def condition
    expect :if
    self[1]
  end

  def condition= exp
    expect :if
    self[1] = exp
  end


  #Returns 'then' clause of an if expression:
  #
  #    s(:if,
  #     s(:lvar, :condition),
  #     s(:lvar, :then_val), <-- then clause
  #     s(:lvar, :else_val)))
  def then_clause
    expect :if
    self[2]
  end

  #Returns 'else' clause of an if expression:
  #
  #    s(:if,
  #     s(:lvar, :condition),
  #     s(:lvar, :then_val),
  #     s(:lvar, :else_val)))
  #     ^---else caluse---^
  def else_clause
    expect :if
    self[3]
  end

  #Method call associated with a block:
  #
  #    s(:iter,
  #     s(:call, nil, :x, s(:arglist)), <- block_call
  #      s(:lasgn, :y),
  #       s(:block, s(:lvar, :y), s(:call, nil, :z, s(:arglist))))
  def block_call
    expect :iter

    if self[1].node_type == :lambda
      s(:call, nil, :lambda).line(self.line)
    else
      self[1]
    end
  end

  #Returns block of a call with a block.
  #Could be a single expression or a block:
  #
  #    s(:iter,
  #     s(:call, nil, :x, s(:arglist)),
  #      s(:lasgn, :y),
  #       s(:block, s(:lvar, :y), s(:call, nil, :z, s(:arglist))))
  #       ^-------------------- block --------------------------^
  def block delete = nil
    unless delete.nil? #this is from RubyParser
      return find_node :block, delete
    end

    expect :iter, :scope, :resbody

    case self.node_type
    when :iter
      self[3]
    when :scope
      self[1]
    when :resbody
      #This is for Ruby2Ruby ONLY
      find_node :block
    end
  end

  #Returns parameters for a block
  #
  #    s(:iter,
  #     s(:call, nil, :x, s(:arglist)),
  #      s(:lasgn, :y), <- block_args
  #       s(:call, nil, :p, s(:arglist, s(:lvar, :y))))
  def block_args
    expect :iter
    if self[2] == 0 # ?! See https://github.com/presidentbeef/brakeman/issues/331
      return Sexp.new(:args)
    else
      self[2]
    end
  end

  def first_param
    expect :args
    self[1]
  end

  #Returns the left hand side of assignment or boolean:
  #
  #    s(:lasgn, :x, s(:lit, 1))
  #               ^--lhs
  def lhs
    expect(*ASSIGNMENT_BOOL)
    self[1]
  end

  #Sets the left hand side of assignment or boolean.
  def lhs= exp
    expect(*ASSIGNMENT_BOOL)
    @my_hash_value = nil
    self[1] = exp
  end

  #Returns right side (value) of assignment or boolean:
  #
  #    s(:lasgn, :x, s(:lit, 1))
  #                  ^--rhs---^
  def rhs
    expect :attrasgn, :safe_attrasgn, *ASSIGNMENT_BOOL

    if self.node_type == :attrasgn or self.node_type == :safe_attrasgn
      if self[2] == :[]=
        self[4]
      else
        self[3]
      end
    else
      self[2]
    end
  end

  #Sets the right hand side of assignment or boolean.
  def rhs= exp
    expect :attrasgn, :safe_attrasgn, *ASSIGNMENT_BOOL
    @my_hash_value = nil

    if self.node_type == :attrasgn or self.node_type == :safe_attrasgn
      self[3] = exp
    else
      self[2] = exp
    end
  end

  #Returns name of method being defined in a method definition.
  def method_name
    expect :defn, :defs

    case self.node_type
    when :defn
      self[1]
    when :defs
      self[2]
    end
  end

  def formal_args
    expect :defn, :defs

    case self.node_type
    when :defn
      self[2]
    when :defs
      self[3]
    end
  end

  #Sets body, which is now a complicated process because the body is no longer
  #a separate Sexp, but just a list of Sexps.
  def body= exp
    expect :defn, :defs, :class, :module
    @my_hash_value = nil

    case self.node_type
    when :defn, :class
      index = 3
    when :defs
      index = 4
    when :module
      index = 2
    end

    self.slice!(index..-1) #Remove old body

    if exp.first == :rlist
      exp = exp.sexp_body
    end

    #Insert new body
    exp.each do |e|
      self[index] = e
      index += 1
    end
  end

  #Returns body of a method definition, class, or module.
  #This will be an untyped Sexp containing a list of Sexps from the body.
  def body
    expect :defn, :defs, :class, :module

    case self.node_type
    when :defn, :class
      self.sexp_body(3)
    when :defs
      self.sexp_body(4)
    when :module
      self.sexp_body(2)
    end
  end

  #Like Sexp#body, except the returned Sexp is of type :rlist
  #instead of untyped.
  def body_list
    self.body.unshift :rlist
  end

  # Number of "statements" in a method.
  # This is more efficient than `Sexp#body.length`
  # because `Sexp#body` creates a new Sexp.
  def method_length
    expect :defn, :defs

    case self.node_type
    when :defn
      self.length - 3
    when :defs
      self.length - 4
    end
  end

  def render_type
    expect :render
    self[1]
  end

  def class_name
    expect :class, :module
    self[1]
  end

  alias module_name class_name

  def parent_name
    expect :class
    self[2]
  end

  #Returns the call Sexp in a result returned from FindCall
  def call
    expect :result

    self.last
  end

  #Returns the module the call is inside
  def module
    expect :result

    self[1]
  end

  #Return the class the call is inside
  def result_class
    expect :result

    self[2]
  end

  require 'set'
  def inspect seen = Set.new
    if seen.include? self.object_id
      's(...)'
    else
      seen << self.object_id
      sexp_str = self.map do |x|
        if x.is_a? Sexp
          x.inspect seen
        else
          x.inspect
        end
      end.join(', ')

      "s(#{sexp_str})"
    end
  end
end

#Invalidate hash cache if the Sexp changes
[:[]=, :clear, :collect!, :compact!, :concat, :delete, :delete_at,
  :delete_if, :drop, :drop_while, :fill, :flatten!, :replace, :insert,
  :keep_if, :map!, :pop, :push, :reject!, :replace, :reverse!, :rotate!,
  :select!, :shift, :shuffle!, :slice!, :sort!, :sort_by!, :transpose,
  :uniq!, :unshift].each do |method|

  Sexp.class_eval <<-RUBY
    def #{method} *args
      @my_hash_value = nil
      super
    end
    RUBY
end

#Methods used by RubyParser which would normally go through method_missing but
#we don't want that to happen because it hides Brakeman errors
[:resbody, :lasgn, :iasgn, :splat].each do |method|
  Sexp.class_eval <<-RUBY
    def #{method} delete = false
      if delete
        @my_hash_value = false
      end
      find_node :#{method}, delete
    end
  RUBY
end

class String
  ##
  # This is a hack used by the lexer to sneak in line numbers at the
  # identifier level. This should be MUCH smaller than making
  # process_token return [value, lineno] and modifying EVERYTHING that
  # reduces tIDENTIFIER.

  attr_accessor :lineno
end

class WrongSexpError < RuntimeError; end
