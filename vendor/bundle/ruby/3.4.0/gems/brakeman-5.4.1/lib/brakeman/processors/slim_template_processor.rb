require 'brakeman/processors/template_processor'
require 'brakeman/processors/lib/render_helper'

class Brakeman::SlimTemplateProcessor < Brakeman::TemplateProcessor
  include Brakeman::RenderHelper

  SAFE_BUFFER = s(:call, s(:colon2, s(:const, :ActiveSupport), :SafeBuffer), :new)
  OUTPUT_BUFFER = s(:ivar, :@output_buffer)
  TEMPLE_UTILS = s(:colon2, s(:colon3, :Temple), :Utils)
  ATTR_MERGE = s(:call, s(:call, s(:array), :reject, s(:block_pass, s(:lit, :empty?))), :join, s(:str, " "))
  EMBEDDED_FILTER = s(:const, :BrakemanFilter)

  def process_call exp
    target = exp.target
    method = exp.method

    if method == :safe_concat and (target == SAFE_BUFFER or target == OUTPUT_BUFFER)
      arg = normalize_output(exp.first_arg)

      if is_escaped? arg
        add_escaped_output arg.first_arg
      elsif string? arg
        ignore
      elsif render? arg
        add_output make_render_in_view arg
      elsif string_interp? arg
        process_inside_interp arg
      elsif node_type? arg, :ignore
        ignore
      elsif internal_variable? arg
        ignore
      elsif arg == ATTR_MERGE
        ignore
      else
        add_output arg
      end
    elsif is_escaped? exp
      add_escaped_output arg
    elsif target == nil and method == :render
      exp.arglist = process exp.arglist
      make_render_in_view exp
    else
      exp.arglist = process exp.arglist
      exp
    end
  end

  def normalize_output arg
    arg = super(arg)

    if embedded_filter? arg
      super(arg.first_arg)
    else
      arg
    end
  end

  # Handle our "fake" embedded filters
  def embedded_filter? arg
    call? arg and arg.method == :render and arg.target == EMBEDDED_FILTER
  end

  #Slim likes to interpolate output into strings then pass them to safe_concat.
  #Better to pull those values out directly.
  def process_inside_interp exp
    exp.map! do |e|
      if node_type? e, :evstr
        e.value = process_interp_output e.value
        e
      else
        e
      end
    end

    exp
  end

  def process_interp_output exp
    if sexp? exp
      if node_type? exp, :if
        process_interp_output exp.then_clause
        process_interp_output exp.else_clause
      elsif exp == SAFE_BUFFER
        ignore
      elsif render? exp
        add_output make_render_in_view exp
      elsif node_type? :output, :escaped_output
        exp
      elsif is_escaped? exp
        add_escaped_output exp
      else
        add_output exp
      end
    end
  end

  def add_escaped_output exp
    exp = normalize_output(exp)

    return exp if string? exp or internal_variable? exp

    super exp
  end

  def is_escaped? exp
    call? exp and
    exp.target == TEMPLE_UTILS and
    (exp.method == :escape_html or exp.method == :escape_html_safe)
  end

  def internal_variable? exp
    node_type? exp, :lvar and
    exp.value =~ /^_(temple_|slim_)/
  end

  def render? exp
    call? exp and
    exp.target.nil? and
    exp.method == :render
  end

  def process_render exp
    #Still confused as to why this is not needed in other template processors
    #but is needed here
    exp
  end
end
