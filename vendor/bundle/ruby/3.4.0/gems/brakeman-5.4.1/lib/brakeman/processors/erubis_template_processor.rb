require 'brakeman/processors/template_processor'

#Processes ERB templates using Erubis instead of erb.
class Brakeman::ErubisTemplateProcessor < Brakeman::TemplateProcessor

  #s(:call, TARGET, :method, ARGS)
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end

    exp.target = target
    exp.arglist = process exp.arglist
    method = exp.method

    #_buf is the default output variable for Erubis
    if node_type?(target, :lvar, :ivar) and (target.value == :_buf or target.value == :@output_buffer)
      if method == :<< or method == :safe_concat

        arg = normalize_output(exp.first_arg)

        if arg.node_type == :str #ignore plain strings
          ignore
        elsif node_type? target, :ivar and target.value == :@output_buffer
          add_escaped_output arg
        else
          add_output arg
        end
      elsif method == :to_s
        ignore
      else
        abort "Unrecognized action on buffer: #{method}"
      end
    elsif target == nil and method == :render
      make_render_in_view exp
    else
      exp
    end
  end

  #Process blocks, ignoring :ignore exps
  def process_block exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      res = process e
      if res.empty? or res == ignore
        nil
      else
        res
      end
    end
    block = Sexp.new(:rlist).concat(exp).compact
    block.line(exp.line)
    block
  end

  #Look for assignments to output buffer that look like this:
  #  @output_buffer.append = some_output
  #  @output_buffer.safe_append = some_output
  #  @output_buffer.safe_expr_append = some_output
  def process_attrasgn exp
    if exp.target.node_type == :ivar and exp.target.value == :@output_buffer
      if append_method?(exp.method)
        exp.first_arg = process(exp.first_arg)
        arg = normalize_output(exp.first_arg)

        if arg.node_type == :str
          ignore
        elsif safe_append_method?(exp.method)
          add_output arg
        else
          add_escaped_output arg
        end
      else
        super
      end
    else
      super
    end
  end

  private
  def append_method?(method)
    method == :append= || safe_append_method?(method)
  end

  def safe_append_method?(method)
    method == :safe_append= || method == :safe_expr_append=
  end
end
