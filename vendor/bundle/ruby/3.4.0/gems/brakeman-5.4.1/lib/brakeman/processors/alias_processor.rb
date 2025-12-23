require 'brakeman/util'
require 'ruby_parser/bm_sexp_processor'
require 'brakeman/processors/lib/processor_helper'
require 'brakeman/processors/lib/safe_call_helper'
require 'brakeman/processors/lib/call_conversion_helper'

#Returns an s-expression with aliases replaced with their value.
#This does not preserve semantics (due to side effects, etc.), but it makes
#processing easier when searching for various things.
class Brakeman::AliasProcessor < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::SafeCallHelper
  include Brakeman::Util
  include Brakeman::CallConversionHelper

  attr_reader :result, :tracker

  #Returns a new AliasProcessor with an empty environment.
  #
  #The recommended usage is:
  #
  # AliasProcessor.new.process_safely src
  def initialize tracker = nil, current_file = nil
    super()
    @env = SexpProcessor::Environment.new
    @inside_if = false
    @ignore_ifs = nil
    @exp_context = []
    @tracker = tracker #set in subclass as necessary
    @helper_method_cache = {}
    @helper_method_info = Hash.new({})
    @or_depth_limit = (tracker && tracker.options[:branch_limit]) || 5 #arbitrary default
    @meth_env = nil
    @current_file = current_file
    set_env_defaults
  end

  #This method processes the given Sexp, but copies it first so
  #the original argument will not be modified.
  #
  #_set_env_ should be an instance of SexpProcessor::Environment. If provided,
  #it will be used as the starting environment.
  #
  #This method returns a new Sexp with variables replaced with their values,
  #where possible.
  def process_safely src, set_env = nil, current_file = @current_file
    @current_file = current_file
    @env = set_env || SexpProcessor::Environment.new
    @result = src.deep_clone
    process @result
    @result
  end

  #Process a Sexp. If the Sexp has a value associated with it in the
  #environment, that value will be returned.
  def process_default exp
    @exp_context.push exp

    begin
      exp.map! do |e|
        if sexp? e and not e.empty?
          process e
        else
          e
        end
      end
    rescue => err
      if @tracker
        @tracker.error err
      else
        raise err
      end
    end

    result = replace(exp)

    @exp_context.pop

    result
  end

  def replace exp, int = 0
    return exp if int > 3

    if replacement = env[exp] and not duplicate? replacement
      replace(replacement.deep_clone(exp.line), int + 1)
    elsif tracker and replacement = tracker.constant_lookup(exp) and not duplicate? replacement
      replace(replacement.deep_clone(exp.line), int + 1)
    else
      exp
    end
  end

  def process_bracket_call exp
    r = replace(exp)

    if r != exp
      return r
    end

    exp.arglist = process_default(exp.arglist)

    r = replace(exp)

    if r != exp
      return r
    end

    t = process(exp.target.deep_clone)

    # sometimes t[blah] has a match in the env
    # but we don't want to actually set the target
    # in case the target is big...which is what this
    # whole method is trying to avoid
    if t != exp.target
      e = exp.deep_clone
      e.target = t

      r = replace(e)

      if r != e
        return r
      end
    else
      t = nil
    end

    if hash? t
      if v = process_hash_access(t, exp.first_arg)
        v.deep_clone(exp.line)
      else
        case t.node_type
        when :params
          exp.target = PARAMS_SEXP.deep_clone(exp.target.line)
        when :session
          exp.target = SESSION_SEXP.deep_clone(exp.target.line)
        when :cookies
          exp.target = COOKIES_SEXP.deep_clone(exp.target.line)
        end

        exp
      end
    elsif array? t
      if v = process_array_access(t, exp.args)
        v.deep_clone(exp.line)
      else
        exp
      end
    elsif t
      exp.target = t
      exp
    else
      if exp.target # `self` target is reported as `nil` https://github.com/seattlerb/ruby_parser/issues/250
        exp.target = process_default exp.target
      end

      exp
    end
  end

  ARRAY_CONST = s(:const, :Array)
  HASH_CONST = s(:const, :Hash)
  RAILS_TEST = s(:call, s(:call, s(:const, :Rails), :env), :test?)
  RAILS_DEV = s(:call, s(:call, s(:const, :Rails), :env), :development?)

  #Process a method call.
  def process_call exp
    return exp if process_call_defn? exp
    target_var = exp.target
    target_var &&= target_var.deep_clone
    if exp.node_type == :safe_call
      exp.node_type = :call
    end

    if exp.method == :[]
      return process_bracket_call exp
    else
      exp = process_default exp
    end

    #In case it is replaced with something else
    unless call? exp
      return exp
    end

    # If x(*[1,2,3]) change to x(1,2,3)
    # if that's the only argument
    if splat_array? exp.first_arg and exp.second_arg.nil?
      exp.arglist = exp.first_arg[1].sexp_body
    end

    target = exp.target
    method = exp.method
    first_arg = exp.first_arg

    if method == :send or method == :__send__ or method == :try
      collapse_send_call exp, first_arg
    end

    if node_type? target, :or and [:+, :-, :*, :/].include? method
      res = process_or_simple_operation(exp)
      return res if res
    elsif target == ARRAY_CONST and method == :new
      return Sexp.new(:array, *exp.args).line(exp.line)
    elsif target == HASH_CONST and method == :new and first_arg.nil? and !node_type?(@exp_context.last, :iter)
      return Sexp.new(:hash).line(exp.line)
    elsif exp == RAILS_TEST or exp == RAILS_DEV
      return Sexp.new(:false).line(exp.line)
    end

    # For the simplest case of `Foo.thing`
    if node_type? target, :const and first_arg.nil?
      if tracker and (klass = tracker.find_class(class_name(target.value)))
        if return_value = klass.get_simple_method_return_value(:class, method)
          return return_value.deep_clone(exp.line)
        end
      end
    end

    #See if it is possible to simplify some basic cases
    #of addition/concatenation.
    case method
    when :+
      if array? target and array? first_arg
        exp = join_arrays(target, first_arg, exp)
      elsif string? first_arg
        exp = join_strings(target, first_arg, exp)
      elsif number? first_arg
        exp = math_op(:+, target, first_arg, exp)
      end
    when :-, :*, :/
      if method == :* and array? target
        if string? first_arg
          exp = process_array_join(target, first_arg)
        end
      else
        exp = math_op(method, target, first_arg, exp)
      end
    when :[]
      if array? target
        exp = process_array_access(target, exp.args, exp)
      elsif hash? target
        exp = process_hash_access(target, first_arg, exp)
      end
    when :fetch
      if array? target
        # Not dealing with default value
        # so just pass in first argument, but process_array_access expects
        # an array of arguments.
        exp = process_array_access(target, [first_arg], exp)
      elsif hash? target
        exp = process_hash_access(target, first_arg, exp)
      end
    when :merge!, :update
      if hash? target and hash? first_arg
         target = process_hash_merge! target, first_arg
         env[target_var] = target
         return target
      end
    when :merge
      if hash? target and hash? first_arg
        return process_hash_merge(target, first_arg)
      end
    when :<<
      if string? target and string? first_arg
        target.value << first_arg.value
        env[target_var] = target
        return target
      elsif string? target and string_interp? first_arg
        exp = Sexp.new(:dstr, target.value + first_arg[1]).concat(first_arg.sexp_body(2)).line(exp.line)
        env[target_var] = exp
      elsif string? first_arg and string_interp? target
        if string? target.last
          target.last.value << first_arg.value
        elsif target.last.is_a? String
          target.last << first_arg.value
        else
          target << first_arg
        end
        env[target_var] = target
        return first_arg
      elsif new_string? target
        env[target_var] = first_arg
        return first_arg
      elsif array? target
        target << first_arg
        env[target_var] = target
        return target
      else
        target = find_push_target(target_var)
        env[target] = exp unless target.nil? # Happens in TemplateAliasProcessor
      end
    when :push
      if array? target
        target << first_arg
        env[target_var] = target
        return target
      end
    when :first
      if array? target and first_arg.nil? and sexp? target[1]
        exp = target[1]
      end
    when :freeze, :dup, :presence
      unless target.nil?
        exp = target
      end
    when :join
      if array? target and (string? first_arg or first_arg.nil?)
        exp = process_array_join(target, first_arg)
      end
    when :!
      #  Convert `!!a` to boolean
      if call? target and target.method == :!
        exp = s(:or, s(:true).line(exp.line), s(:false).line(exp.line)).line(exp.line)
      end
    when :values
      # Hash literal
      if node_type? target, :hash
        exp = hash_values(target)
      end
    when :values_at
      if node_type? target, :hash
        res = hash_values_at target, exp.args

        # Only convert to array of values if _all_ keys
        # are present in the hash.
        unless res.any?(&:nil?)
          exp = res
        end
      end
    when :presence_in
      arg = exp.first_arg

      if node_type? arg, :array
        # 1.presence_in [1,2,3]
        if arg.include? target
          exp = target
        elsif all_literals? arg
          exp = safe_literal(exp.line)
        end
      end
    end

    exp
  end

  # Painful conversion of Array#join into string interpolation
  def process_array_join array, join_str
    # Empty array
    if array.length == 1
      return s(:str, '').line(array.line)
    end

    result = s().line(array.line)

    join_value = if string? join_str
                   join_str.value
                 else
                   nil
                 end

    if array.length > 2
      array[1..-2].each do |e|
        result << join_item(e, join_value)
      end
    end

    result << join_item(array.last, nil)

    # Combine the strings at the beginning because that's what RubyParser does
    combined_first = ""
    result.each do |e|
      if string? e
        combined_first << e.value
      elsif e.is_a? String
        combined_first << e
      else
        break
      end
    end

    # Remove the strings at the beginning
    result.reject! do |e|
      if e.is_a? String or string? e
        true
      else
        break
      end
    end

    result.unshift combined_first

    # Have to fix up strings that follow interpolation
    string = result.reduce(s(:dstr).line(array.line)) do |memo, e|
      if string? e and node_type? memo.last, :evstr
        e.value = "#{join_value}#{e.value}"
      elsif join_value and node_type? memo.last, :evstr and node_type? e, :evstr
        memo << s(:str, join_value).line(e.line)
      end

      memo << e
    end

    # Convert (:dstr, "hello world")
    # to (:str, "hello world")
    if string.length == 2 and string.last.is_a? String
      string[0] = :str
    end

    string
  end

  def join_item item, join_value
    if item.nil? || item.is_a?(String)
      "#{item}#{join_value}"
    elsif string? item or symbol? item or number? item
      s(:str, "#{item.value}#{join_value}").line(item.line)
    else
      s(:evstr, item).line(item.line)
    end
  end

  TEMP_FILE_CLASS = s(:const, :Tempfile)

  def temp_file_open? exp
    call? exp and
      exp.target == TEMP_FILE_CLASS and
      exp.method == :open
  end

  def temp_file_new line
    s(:call, TEMP_FILE_CLASS, :new).line(line)
  end

  def splat_array? exp
    node_type? exp, :splat and
      node_type? exp[1], :array
  end

  def process_iter exp
    @exp_context.push exp
    exp[1] = process exp.block_call
    if array_detect_all_literals? exp[1]
      return safe_literal(exp.line)
    end

    @exp_context.pop

    env.scope do
      call = exp.block_call
      block_args = exp.block_args

      if call? call and [:each, :map].include? call.method and all_literals? call.target and block_args.length == 2 and block_args.last.is_a? Symbol
        # Iterating over an array of all literal values
        local = Sexp.new(:lvar, block_args.last)
        env.current[local] = safe_literal(exp.line)
      elsif temp_file_open? call
        local = Sexp.new(:lvar, block_args.last)
        env.current[local] = temp_file_new(exp.line)
      else
        block_args.each do |e|
          #Force block arg(s) to be local
          if node_type? e, :lasgn
            env.current[Sexp.new(:lvar, e.lhs)] = Sexp.new(:lvar, e.lhs)
          elsif node_type? e, :kwarg
            env.current[Sexp.new(:lvar, e[1])] = e[2]
          elsif node_type? e, :masgn, :shadow
            e[1..-1].each do |var|
              local = Sexp.new(:lvar, var)
              env.current[local] = local
            end
          elsif e.is_a? Symbol
            local = Sexp.new(:lvar, e)
            env.current[local] = local
          elsif e.nil? # trailing comma, argument destructuring
            next # Punt for now
          else
            raise "Unexpected value in block args: #{e.inspect}"
          end
        end
      end

      block = exp.block

      if block? block
        process_all! block
      else
        exp[3] = process block
      end
    end

    exp
  end

  #Process a new scope.
  def process_scope exp
    env.scope do
      process exp.block
    end
    exp
  end

  #Start new scope for block.
  def process_block exp
    env.scope do
      process_default exp
    end
  end

  #Process a method definition.
  def process_defn exp
    meth_env do
      exp.body = process_all! exp.body
    end
    exp
  end

  def meth_env
    begin
      env.scope do
        set_env_defaults
        @meth_env = env.current
        yield
      end
    ensure
      @meth_env = nil
    end
  end

  #Process a method definition on self.
  def process_defs exp
    env.scope do
      set_env_defaults
      exp.body = process_all! exp.body
    end
    exp
  end

  # Handles x = y = z = 1
  def get_rhs exp
    if node_type? exp, :lasgn, :iasgn, :gasgn, :attrasgn, :safe_attrasgn, :cvdecl, :cdecl
      get_rhs(exp.rhs)
    else
      exp
    end
  end

  #Local assignment
  # x = 1
  def process_lasgn exp
    self_assign = self_assign?(exp.lhs, exp.rhs)
    exp.rhs = process exp.rhs if sexp? exp.rhs
    return exp if exp.rhs.nil?

    local = Sexp.new(:lvar, exp.lhs).line(exp.line || -2)

    if self_assign
      # Skip branching
      env[local] = get_rhs(exp)
    else
      set_value local, get_rhs(exp)
    end

    exp
  end

  #Instance variable assignment
  # @x = 1
  def process_iasgn exp
    self_assign = self_assign?(exp.lhs, exp.rhs)
    exp.rhs = process exp.rhs
    ivar = Sexp.new(:ivar, exp.lhs).line(exp.line)

    if self_assign
      if env[ivar].nil? and @meth_env
        @meth_env[ivar] = get_rhs(exp)
      else
        env[ivar] = get_rhs(exp)
      end
    else
      set_value ivar, get_rhs(exp)
    end

    exp
  end

  #Global assignment
  # $x = 1
  def process_gasgn exp
    match = Sexp.new(:gvar, exp.lhs)
    exp.rhs = process(exp.rhs)
    value = get_rhs(exp)

    if value
      value.line = exp.line

      set_value match, value
    end

    exp
  end

  #Class variable assignment
  # @@x = 1
  def process_cvdecl exp
    match = Sexp.new(:cvar, exp.lhs)
    exp.rhs = process(exp.rhs)
    value = get_rhs(exp)

    set_value match, value

    exp
  end

  #'Attribute' assignment
  # x.y = 1
  #or
  # x[:y] = 1
  def process_attrasgn exp
    tar_variable = exp.target
    target = process(exp.target)
    method = exp.method
    index_arg = exp.first_arg
    value_arg = exp.second_arg

    if method == :[]=
      index = exp.first_arg = process(index_arg)
      value = exp.second_arg = process(value_arg)
      match = Sexp.new(:call, target, :[], index)

      set_value match, value

      if hash? target
        env[tar_variable] = hash_insert target.deep_clone, index, value
      end

      unless node_type? target, :hash
        exp.target = target
      end
    elsif method.to_s[-1,1] == "="
      exp.first_arg = process(index_arg)
      value = get_rhs(exp)
      #This is what we'll replace with the value
      match = Sexp.new(:call, target, method.to_s[0..-2].to_sym)

      set_value match, value
      exp.target = target
    else
      raise "Unrecognized assignment: #{exp}"
    end
    exp
  end

  # Multiple/parallel assignment:
  #
  # x, y = z, w
  def process_masgn exp
    exp[2] = process exp[2] if sexp? exp[2]

    if node_type? exp[2], :to_ary and array? exp[2][1]
      exp[2] = exp[2][1]
    end

    unless array? exp[1] and array? exp[2] and exp[1].length == exp[2].length
      return process_default(exp)
    end

    vars = exp[1].dup
    vals = exp[2].dup

    vars.shift
    vals.shift

    # Call each assignment as if it is normal
    vars.each_with_index do |var, i|
      val = vals[i]
      if val

        # This happens with nested destructuring like
        #   x, (a, b) = blah
        if node_type? var, :masgn
          # Need to add value to masgn exp
          m = var.dup
          m[2] = s(:to_ary, val)

          process_masgn m
        else
          assign = var.dup
          assign.rhs = val
          process assign
        end
      end
    end

    exp
  end

  def process_hash exp
    exp = process_default(exp)

    # Handle { **kw }
    if node_type? exp, :hash
      if exp.any? { |e| node_type? e, :kwsplat and node_type? e.value, :hash }
        kwsplats, rest = exp.partition { |e| node_type? e, :kwsplat and node_type? e.value, :hash }
        exp = Sexp.new.concat(rest).line(exp.line)

        kwsplats.each do |e|
          exp = process_hash_merge! exp, e.value
        end
      end
    end

    # Return early unless there might be short-hand syntax,
    # since handling it is kind of expensive.
    return exp unless exp.any? { |e| e.nil? }

    # Need to handle short-hand hash syntax
    new_hash = [:hash]
    hash_iterate(exp) do |key, value|
      # e.g. { a: }
      if value.nil? and symbol? key
        # Only handling local variables for now, not calls
        lvar = s(:lvar, key.value)
        if var_value = env[lvar]
          new_hash << key << var_value.deep_clone(key.line || 0)
        else
          # If the value is unknown, assume it was a call
          # and set the value to a call
          new_hash.concat << key << s(:call, nil, key.value).line(key.line || 0)
        end
      else
        new_hash.concat << key << value
      end
    end

    Sexp.from_array(new_hash).line(exp.line || 0)
  end

  #Merge values into hash when processing
  #
  # h.merge! :something => "value"
  def process_hash_merge! hash, args
    hash = hash.deep_clone
    hash_iterate args do |key, replacement|
      hash_insert hash, key, replacement
      match = Sexp.new(:call, hash, :[], key)
      env[match] = replacement
    end
    hash
  end

  #Return a new hash Sexp with the given values merged into it.
  #
  #+args+ should be a hash Sexp as well.
  def process_hash_merge hash, args
    hash = hash.deep_clone
    hash_iterate args do |key, replacement|
      hash_insert hash, key, replacement
    end
    hash
  end

  #Assignments like this
  # x[:y] ||= 1
  def process_op_asgn1 exp
    target_var = exp[1]
    target_var &&= target_var.deep_clone

    target = exp[1] = process(exp[1])
    index = exp[2][1] = process(exp[2][1])
    value = exp[4] = process(exp[4])
    match = Sexp.new(:call, target, :[], index)

    if exp[3] == :"||"
      unless env[match]
        if request_value? target
          env[match] = match.combine(value)
        else
          env[match] = value
        end
      end
    else
      new_value = process s(:call, s(:call, target_var, :[], index), exp[3], value).line(exp.line)

      env[match] = new_value
    end

    exp
  end

  #Assignments like this
  # x.y ||= 1
  def process_op_asgn2 exp
    return process_default(exp) if exp[3] != :"||"

    target = exp[1] = process(exp[1])
    value = exp[4] = process(exp[4])
    method = exp[2]

    match = Sexp.new(:call, target, method.to_s[0..-2].to_sym)

    unless env[match]
      env[match] = value
    end

    exp
  end

  #This is the right hand side value of a multiple assignment,
  #like `x = y, z`
  def process_svalue exp
    exp.value
  end

  #Constant assignments like
  # BIG_CONSTANT = 234810983
  def process_cdecl exp
    if sexp? exp.rhs
      exp.rhs = process exp.rhs
    end

    if @tracker
      @tracker.add_constant exp.lhs,
        exp.rhs,
        :file => @current_file,
        :module => @current_module,
        :class => @current_class,
        :method => @current_method
    end

    if exp.lhs.is_a? Symbol
      match = Sexp.new(:const, exp.lhs)
    else
      match = exp.lhs
    end

    env[match] = get_rhs(exp)

    exp
  end

  def hash_or_array_include_all_literals? exp
    return unless call? exp and sexp? exp.target
    target = exp.target

    case target.node_type
    when :hash
      hash_include_all_literals? exp
    else
      array_include_all_literals? exp
    end
  end

  # Check if exp is a call to Array#include? on an array literal
  # that contains all literal values. For example:
  #
  #    [1, 2, "a"].include? x
  #
  def array_include_all_literals? exp
    call? exp and
    exp.method == :include? and
    (all_literals? exp.target or dir_glob? exp.target)
  end

  def array_detect_all_literals? exp
    call? exp and
    [:detect, :find].include? exp.method and
    exp.first_arg.nil? and
    (all_literals? exp.target or dir_glob? exp.target)
  end

  # Check if exp is a call to Array#include? on an array literal
  # that contains all literal values. For example:
  #
  #    x.in? [1, 2, "a"]
  #
  def in_array_all_literals? exp
    call? exp and
      exp.method == :in? and
      all_literals? exp.first_arg
  end

  # Check if exp is a call to Hash#include? on a hash literal
  # that contains all literal values. For example:
  #
  #    {x: 1}.include? x
  def hash_include_all_literals? exp
    call? exp and
    exp.method == :include? and
    all_literals? exp.target, :hash
  end

  #Sets @inside_if = true
  def process_if exp
    if @ignore_ifs.nil?
      @ignore_ifs = @tracker && @tracker.options[:ignore_ifs]
    end

    condition = exp.condition = process exp.condition

    #Check if a branch is obviously going to be taken
    if true? condition
      no_branch = true
      exps = [exp.then_clause, nil]
    elsif false? condition
      no_branch = true
      exps = [nil, exp.else_clause]
    elsif equality_check? condition and condition.target == condition.first_arg
      no_branch = true
      exps = [exp.then_clause, nil]
    else
      no_branch = false
      exps = [exp.then_clause, exp.else_clause]
    end

    if @ignore_ifs or no_branch
      exps.each_with_index do |branch, i|
        exp[2 + i] = process_if_branch branch
      end
    else
      # Translate `if !...` into `unless ...`
      # Technically they are different but that's only if someone overrides `!`
      if call? condition and condition.method == :!
        condition = condition.target
        exps.reverse!
      end

      was_inside = @inside_if
      @inside_if = true

      branch_scopes = []
      exps.each_with_index do |branch, i|
        scope do
          @branch_env = env.current
          branch_index = 2 + i # s(:if, condition, then_branch, else_branch)
         exp[branch_index] = if i == 0 and hash_or_array_include_all_literals? condition
            # If the condition is ["a", "b"].include? x
            # set x to safe_literal inside the true branch
            var = condition.first_arg
            value = safe_literal(var.line)
            process_branch_with_value(var, value, branch, i)
          elsif i == 0 and in_array_all_literals? condition
            # If the condition is x.in? ["a", "b"]
            # set x to safe_literal inside the true branch
            var = condition.target
            value = safe_literal(var.line)
            process_branch_with_value(var, value, branch, i)
          elsif i == 0 and equality_check? condition
            # For conditions like a == b,
            # set a to b inside the true branch
            var = condition.target
            value = condition.first_arg
            process_branch_with_value(var, value, branch, i)
          elsif i == 1 and hash_or_array_include_all_literals? condition and early_return? branch
            var = condition.first_arg
            env.current[var] = safe_literal(var.line)
            process_if_branch branch
          else
            process_if_branch branch
          end
          branch_scopes << env.current
          @branch_env = nil
        end
      end

      @inside_if = was_inside

      branch_scopes.each do |s|
        merge_if_branch s
      end
    end

    exp
  end

  def process_branch_with_value var, value, branch, branch_index
    previous_value = env.current[var]
    env.current[var] = value
    result = process_if_branch branch
    env.current[var] = previous_value
    result
  end

  def early_return? exp
    return true if node_type? exp, :return
    return true if call? exp and [:fail, :raise].include? exp.method

    if node_type? exp, :block, :rlist
      node_type? exp.last, :return or
        (call? exp and [:fail, :raise].include? exp.method)
    else
      false
    end
  end

  def equality_check? exp
    call? exp and
      exp.method == :==
  end

  # Not a list of values
  #   when :example
  def simple_when? exp
    node_type? exp[1], :array and
      exp[1].length == 2 and # only one element in the array
      not node_type? exp[1][1], :splat, :array
  end

  # A list of literal values
  #
  #   when 1,2,3
  #
  # or
  #
  #   when *[:a, :b]
  def all_literals_when? exp
    if array? exp[1] # pretty sure this is always true
      all_literals? exp[1] or # simple list, not actually array
        (splat_array? exp[1][1] and
         all_literals? exp[1][1][1])
    end
  end

  def process_case exp
    if @ignore_ifs.nil?
      @ignore_ifs = @tracker && @tracker.options[:ignore_ifs]
    end

    if @ignore_ifs
      process_default exp
      return exp
    end

    branch_scopes = []
    was_inside = @inside_if
    @inside_if = true

    exp[1] = process exp[1] if exp[1]

    case_value = if node_type? exp[1], :lvar, :ivar, :call
      exp[1].deep_clone
    end

    exp.each_sexp do |e|
      if node_type? e, :when
        scope do
          # Process the when value for matching
          process_default e[1]

          # Moved here to avoid @branch_env being cleared out
          # in process_default
          # Maybe in the future don't set it to nil?
          @branch_env = env.current

          # set value of case var if possible
          if case_value
            if simple_when? e
              @branch_env[case_value] = e[1][1]
            elsif all_literals_when? e
              @branch_env[case_value] = safe_literal(e.line + 1)
            end
          end

          # when blocks aren't blocks, they are lists of expressions
          process_default e

          branch_scopes << env.current

          @branch_env = nil
        end
      end
    end

    # else clause
    if sexp? exp.last
      scope do
        @branch_env = env.current

        process_default exp[-1]

        branch_scopes << env.current

        @branch_env = nil
      end
    end

    @inside_if = was_inside

    branch_scopes.each do |s|
      merge_if_branch s
    end

    exp
  end

  def process_if_branch exp
    if sexp? exp
      if block? exp
        process_default exp
      else
        process exp
      end
    end
  end

  def merge_if_branch branch_env
    branch_env.each do |k, v|
      next if v.nil?

      current_val = env[k]

      if current_val
        unless same_value?(current_val, v)
          if too_deep? current_val
            # Give up branching, start over with latest value
            env[k] = v
          else
            env[k] = current_val.combine(v, k.line)
          end
        end
      else
        env[k] = v
      end
    end
  end

  def too_deep? exp
    @or_depth_limit >= 0 and
    node_type? exp, :or and
    exp.or_depth and
    exp.or_depth >= @or_depth_limit
  end

  # Change x.send(:y, 1) to x.y(1)
  def collapse_send_call exp, first_arg
    # Handle try(&:id)
    if node_type? first_arg, :block_pass
      first_arg = first_arg[1]
    end

    return unless symbol? first_arg or string? first_arg
    exp.method = first_arg.value.to_sym
    args = exp.args
    exp.pop # remove last arg
    if args.length > 1
      exp.arglist = args.sexp_body
    end
  end

  #Returns a new SexpProcessor::Environment containing only instance variables.
  #This is useful, for example, when processing views.
  def only_ivars include_request_vars = false, lenv = nil
    lenv ||= env
    res = SexpProcessor::Environment.new

    if include_request_vars
      lenv.all.each do |k, v|
        #TODO Why would this have nil values?
        if (k.node_type == :ivar or request_value? k) and not v.nil?
          res[k] = v.dup
        end
      end
    else
      lenv.all.each do |k, v|
        #TODO Why would this have nil values?
        if k.node_type == :ivar and not v.nil?
          res[k] = v.dup
        end
      end
    end

    res
  end

  def only_request_vars
    res = SexpProcessor::Environment.new

    env.all.each do |k, v|
      if request_value? k and not v.nil?
        res[k] = v.dup
      end
    end

    res
  end

  def get_call_value call
    method_name = call.method

    #Look for helper methods and see if we can get a return value
    if found_method = tracker.find_method(method_name, @current_class)
      helper = found_method.src

      if sexp? helper
        value = process_helper_method helper, call.args
        value.line(call.line)
        return value
      else
        raise "Unexpected value for method: #{found_method}"
      end
    else
      call
    end
  end

  def process_helper_method method_exp, args
    method_name = method_exp.method_name
    Brakeman.debug "Processing method #{method_name}"

    info = @helper_method_info[method_name]

    #If method uses instance variables, then include those and request
    #variables (params, etc) in the method environment. Otherwise,
    #only include request variables.
    if info[:uses_ivars]
      meth_env = only_ivars(:include_request_vars)
    else
      meth_env = only_request_vars
    end

    #Add arguments to method environment
    assign_args method_exp, args, meth_env


    #Find return values if method does not depend on environment/args
    values = @helper_method_cache[method_name]

    unless values
      #Serialize environment for cache key
      meth_values = meth_env.instance_variable_get(:@env).to_a
      meth_values.sort!
      meth_values = meth_values.to_s

      digest = Digest::SHA1.new.update(meth_values << method_name.to_s).to_s.to_sym

      values = @helper_method_cache[digest]
    end

    if values
      #Use values from cache
      values[:ivar_values].each do |var, val|
        env[var] = val
      end

      values[:return_value]
    else
      #Find return value for method
      frv = Brakeman::FindReturnValue.new
      value = frv.get_return_value(method_exp.body_list, meth_env)

      ivars = {}

      only_ivars(false, meth_env).all.each do |var, val|
        env[var] = val
        ivars[var] = val
      end

      if not frv.uses_ivars? and args.length == 0
        #Store return value without ivars and args if they are not used
        @helper_method_cache[method_exp.method_name] = { :return_value => value, :ivar_values => ivars }
      else
        @helper_method_cache[digest] = { :return_value => value, :ivar_values => ivars }
      end

      #Store information about method, just ivar usage for now
      @helper_method_info[method_name] = { :uses_ivars => frv.uses_ivars? }

      value
    end
  end

  def assign_args method_exp, args, meth_env = SexpProcessor::Environment.new
    formal_args = method_exp.formal_args

    formal_args.each_with_index do |arg, index|
      next if index == 0

      if arg.is_a? Symbol and sexp? args[index - 1]
        meth_env[Sexp.new(:lvar, arg)] = args[index - 1]
      end
    end

    meth_env
  end

  #Finds the inner most call target which is not the target of a call to <<
  def find_push_target exp
    if call? exp and exp.method == :<<
      find_push_target exp.target
    else
      exp
    end
  end

  def duplicate? exp
    @exp_context[0..-2].reverse_each do |e|
      return true if exp == e
    end

    false
  end

  def find_method *args
    nil
  end

  #Return true if lhs == rhs or lhs is an or expression and
  #rhs is one of its values
  def same_value? lhs, rhs
    if lhs == rhs
      true
    elsif node_type? lhs, :or
      lhs.rhs == rhs or lhs.lhs == rhs
    else
      false
    end
  end

  def self_assign? var, value
    self_assign_var?(var, value) or self_assign_target?(var, value)
  end

  #Return true if for x += blah or @x += blah
  def self_assign_var? var, value
    call? value and
    value.method == :+ and
    node_type? value.target, :lvar, :ivar and
    value.target.value == var
  end

  #Return true for x = x.blah
  def self_assign_target? var, value
    target = top_target(value)

    if node_type? target, :lvar, :ivar
      target = target.value
    end

    var == target
  end

  #Returns last non-nil target in a call chain
  def top_target exp, last = nil
    if call? exp
      top_target exp.target, exp
    elsif node_type? exp, :iter
      top_target exp.block_call, last
    else
      exp || last
    end
  end

  def value_from_if exp
    if block? exp.else_clause or block? exp.then_clause
      #If either clause is more than a single expression, just use entire
      #if expression for now
      exp
    elsif exp.else_clause.nil?
      exp.then_clause
    elsif exp.then_clause.nil?
      exp.else_clause
    else
      condition = exp.condition

      if true? condition
        exp.then_clause
      elsif false? condition
        exp.else_clause
      else
        exp.then_clause.combine(exp.else_clause, exp.line)
      end
    end
  end

  def value_from_case exp
    result = []

    exp.each do |e|
      if node_type? e, :when
        result << e.last
      end
    end

    result << exp.last if exp.last # else

    result.reduce do |c, e|
      if c.nil?
        e
      elsif node_type? e, :if
        c.combine(value_from_if e)
      elsif raise? e
        c # ignore exceptions
      elsif e
        c.combine e
      else # when e is nil
        c
      end
    end
  end

  def raise? exp
    call? exp and exp.method == :raise
  end

  STRING_NEW = s(:call, s(:const, :String), :new)

  # String.new ?
  def new_string? exp
    exp == STRING_NEW
  end

  #Set variable to given value.
  #Creates "branched" versions of values when appropriate.
  #Avoids creating multiple branched versions inside same
  #if branch.
  def set_value var, value
    if node_type? value, :if
      value = value_from_if(value)
    elsif node_type? value, :case
      value = value_from_case(value)
    end

    if @ignore_ifs or not @inside_if
      if @meth_env and node_type? var, :ivar and env[var].nil?
        @meth_env[var] = value
      else
        env[var] = value
      end
    elsif env.current[var]
      env.current[var] = value
    elsif @branch_env and @branch_env[var]
      @branch_env[var] = value
    elsif @branch_env and @meth_env and node_type? var, :ivar
      @branch_env[var] = value
    else
      env.current[var] = value
    end
  end

  #If possible, distribute operation over both sides of an or.
  #For example,
  #
  #    (1 or 2) * 5
  #
  #Becomes
  #
  #    (5 or 10)
  #
  #Only works for strings and numbers right now.
  def process_or_simple_operation exp
    arg = exp.first_arg
    return nil unless string? arg or number? arg

    target = exp.target
    lhs = process_or_target(target.lhs, exp.dup)
    rhs = process_or_target(target.rhs, exp.dup)

    if lhs and rhs
      if same_value? lhs, rhs
        lhs
      else
        exp.target.lhs = lhs
        exp.target.rhs = rhs
        exp.target
      end
    else
      nil
    end
  end

  def process_or_target value, copy
    if string? value or number? value
      copy.target = value
      process copy
    else
      false
    end
  end
end
