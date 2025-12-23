require 'brakeman/processors/template_processor'

#Processes ERB templates
#(those ending in .html.erb or .rthml).
class Brakeman::ErbTemplateProcessor < Brakeman::TemplateProcessor
  
  #s(:call, TARGET, :method, ARGS)
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end
    method = exp.method
    
    #_erbout is the default output variable for erb
    if node_type? target, :lvar and target.value == :_erbout
      if method == :concat or method == :<<
        @inside_concat = true
        exp.arglist = process(exp.arglist)
        @inside_concat = false

        if exp.second_arg
          raise "Did not expect more than a single argument to _erbout.concat"
        end

        arg = normalize_output(exp.first_arg)

        if arg.node_type == :str #ignore plain strings
          ignore
        else
          add_output arg
        end
      elsif method == :force_encoding
        ignore
      else
        abort "Unrecognized action on _erbout: #{method}"
      end
    elsif target == nil and method == :render
      exp.arglist = process(exp.arglist)
      make_render_in_view exp
    else
      exp.target = target
      exp.arglist = process(exp.arglist)
      exp
    end
  end

  #Process block, removing irrelevant expressions
  def process_block exp
    exp = exp.dup
    exp.shift
    if @inside_concat
      @inside_concat = false
      exp[0..-2].each do |e|
        process e
      end
      @inside_concat = true
      process exp.last
    else
      exp.map! do |e|
        res = process e
        if res.empty? or res == ignore
          nil
        elsif node_type?(res, :lvar) and res.value == :_erbout
          nil

        else
          res
        end
      end
      block = Sexp.new(:rlist).concat(exp).compact
      block.line(exp.line)
      block
    end
  end

end
