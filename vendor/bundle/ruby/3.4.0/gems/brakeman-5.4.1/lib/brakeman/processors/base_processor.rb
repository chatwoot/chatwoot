require 'brakeman/processors/lib/processor_helper'
require 'brakeman/processors/lib/safe_call_helper'
require 'brakeman/util'

#Base processor for most processors.
class Brakeman::BaseProcessor < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::SafeCallHelper
  include Brakeman::Util

  IGNORE = Sexp.new(:ignore).line(0)

  #Return a new Processor.
  def initialize tracker
    super()
    @last = nil
    @tracker = tracker
    @app_tree = tracker.app_tree if tracker
    @current_template = @current_module = @current_class = @current_method = @current_file = nil
  end

  def process_file exp, current_file
    @current_file = current_file
    process exp
  end

  def ignore
    IGNORE
  end

  #Process a new scope. Removes expressions that are set to nil.
  def process_scope exp
    #NOPE?
  end

  #Default processing.
  def process_default exp
    exp = exp.dup

    exp.each_with_index do |e, i|
      exp[i] = process e if sexp? e and not e.empty?
    end

    exp
  end

  #Process an if statement.
  def process_if exp
    exp = exp.dup
    condition = exp[1] = process exp.condition

    if true? condition
      exp[2] = process exp.then_clause if exp.then_clause
      exp[3] = nil
    elsif false? condition
      exp[2] = nil
      exp[3] = process exp.else_clause if exp.else_clause
    else
      exp[2] = process exp.then_clause if exp.then_clause
      exp[3] = process exp.else_clause if exp.else_clause
    end

    exp
  end

  #Processes calls with blocks.
  #
  #s(:iter, CALL, {:lasgn|:masgn}, BLOCK)
  def process_iter exp
    exp = exp.dup
    call = process exp.block_call
    #deal with assignments somehow
    if exp.block
      block = process exp.block
      block = nil if block.empty?
    else
      block = nil
    end

    call = Sexp.new(:iter, call, exp.block_args, block).compact
    call.line(exp.line)
    call
  end

  #String with interpolation.
  def process_dstr exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      if e.is_a? String
        e
      else
        res = process e
        if res.empty?
          nil
        else
          res
        end
      end
    end.compact!

    exp.unshift :dstr
  end

  #Processes a block. Changes Sexp node type to :rlist
  def process_block exp
    exp = exp.dup
    exp.shift

    exp.map! do |e|
      process e
    end

    exp.unshift :rlist
  end

  alias process_rlist process_block

  #Processes the inside of an interpolated String.
  def process_evstr exp
    exp = exp.dup
    if exp[1]
      exp[1] = process exp[1]
    end

    exp
  end

  #Processes a hash
  def process_hash exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      if sexp? e
        process e
      else
        e
      end
    end

    exp.unshift :hash
  end

  #Processes the values in an argument list
  def process_arglist exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      process e
    end

    exp.unshift :arglist
  end

  #Processes a local assignment
  def process_lasgn exp
    exp = exp.dup
    exp.rhs = process exp.rhs
    exp
  end

  alias :process_iasgn :process_lasgn

  #Processes an instance variable assignment
  def process_iasgn exp
    exp = exp.dup
    exp.rhs = process exp.rhs
    exp
  end

  #Processes an attribute assignment, which can be either x.y = 1 or x[:y] = 1
  def process_attrasgn exp
    exp = exp.dup
    exp.target = process exp.target
    exp.arglist = process exp.arglist
    exp
  end

  #Ignore ignore Sexps
  def process_ignore exp
    exp
  end

  def process_cdecl exp
    if @tracker
      @tracker.add_constant exp.lhs,
        exp.rhs,
        :file => current_file,
        :module => @current_module,
        :class => @current_class,
        :method => @current_method
    end

    exp
  end

  #Convenience method for `make_render exp, true`
  def make_render_in_view exp
    make_render exp, true
  end

  #Generates :render node from call to render.
  def make_render exp, in_view = false 
    render_type, value, rest = find_render_type exp, in_view
    rest = process rest
    result = Sexp.new(:render, render_type, value, rest)
    result.line(exp.line)
    result
  end

  #Determines the type of a call to render.
  #
  #Possible types are:
  #:action, :default, :file, :inline, :js, :json, :nothing, :partial,
  #:template, :text, :update, :xml
  #
  #And also :layout for inside templates
  def find_render_type call, in_view = false
    rest = Sexp.new(:hash).line(call.line)
    type = nil
    value = nil
    first_arg = call.first_arg

    if call.second_arg.nil? and first_arg == Sexp.new(:lit, :update)
      return :update, nil, Sexp.new(:arglist, *call.args[0..-2]) #TODO HUH?
    end

    #Look for render :action, ... or render "action", ...
    if string? first_arg or symbol? first_arg
      if @current_template and @tracker.options[:rails3]
        type = :partial
        value = first_arg
      else
        type = :action
        value = first_arg
      end
    elsif first_arg.is_a? Symbol or first_arg.is_a? String
      type = :action
      value = Sexp.new(:lit, first_arg.to_sym).line(call.line)
    elsif first_arg.nil?
      type = :default
    elsif not hash? first_arg
      type = :action
      value = first_arg
    end

    types_in_hash = Set[:action, :file, :inline, :js, :json, :nothing, :partial, :template, :text, :update, :xml]

    #render :layout => "blah" means something else when in a template
    if in_view
      types_in_hash << :layout
    end

    last_arg = call.last_arg

    #Look for "type" of render in options hash
    #For example, render :file => "blah"
    if hash? last_arg
      hash_iterate(last_arg) do |key, val|
        if symbol? key and types_in_hash.include? key.value
          type = key.value
          value = val
        else  
          rest << key << val
        end
      end
    end

    type ||= :default
    value ||= :default

    if type == :inline and string? value and not hash_access(rest, :type)
      value, rest = make_inline_render(value, rest)
    end

    return type, value, rest
  end

  def make_inline_render value, options
    require 'brakeman/parsers/template_parser'

    class_or_module = (@current_class || @current_module)

    class_or_module = if class_or_module.nil?
                        "Unknown"
                      else
                        class_or_module.name
                      end

    template_name = "#@current_method/inline@#{value.line}:#{class_or_module}".to_sym
    type, ast = Brakeman::TemplateParser.parse_inline_erb(@tracker, value.value)
    ast = ast.deep_clone(value.line)
    @tracker.processor.process_template(template_name, ast, type, nil, @current_file)
    @tracker.processor.process_template_alias(@tracker.templates[template_name])

    return s(:lit, template_name).line(value.line), options
  end
end
