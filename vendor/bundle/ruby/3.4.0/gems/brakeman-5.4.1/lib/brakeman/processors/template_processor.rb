require 'brakeman/processors/base_processor'
require 'brakeman/tracker/template'

#Base Processor for templates/views
class Brakeman::TemplateProcessor < Brakeman::BaseProcessor

  #Initializes template information.
  def initialize tracker, template_name, called_from = nil, current_file = nil
    super(tracker)
    @current_template = Brakeman::Template.new template_name, called_from, current_file, tracker
    @current_file = @current_template.file

    if called_from
      template_name = (template_name.to_s + "." + called_from.to_s).to_sym
    end

    tracker.templates[template_name] = @current_template

    @inside_concat = false
  end

  #Process the template Sexp.
  def process exp
    begin
      super
    rescue => e
      except = e.exception("Error when processing #{@current_template.name}: #{e.message}")
      except.set_backtrace(e.backtrace)
      raise except
    end
  end

  #Ignore initial variable assignment
  def process_lasgn exp
    if exp.lhs == :_erbout and exp.rhs.node_type == :str  #ignore
      ignore
    elsif exp.lhs == :_buf and exp.rhs.node_type == :str
      ignore
    else
      exp.rhs = process exp.rhs
      exp
    end
  end

  #Adds output to the list of outputs.
  def process_output exp
    exp.value = process exp.value
    @current_template.add_output exp unless exp.original_line
    exp
  end

  def process_escaped_output exp
    process_output exp
  end

  # Pull out actual output value from template
  def normalize_output arg
    if call? arg and [:to_s, :html_safe!, :freeze].include? arg.method
      arg.target
    elsif node_type? arg, :if
      branches = [arg.then_clause, arg.else_clause].compact

      if branches.empty?
        s(:nil).line(arg.line)
      elsif branches.length == 2
        Sexp.new(:or, *branches).line(arg.line)
      else
        branches.first
      end
    else
      arg
    end
  end

  def add_escaped_output output
    add_output output, :escaped_output
  end

  def add_output output, type = :output
    if node_type? output, :or
      Sexp.new(:or, add_output(output.lhs, type), add_output(output.rhs, type)).line(output.line)
    else
      s = Sexp.new(type, output)
      s.line(output.line)
      @current_template.add_output s
      s
    end
  end
end
