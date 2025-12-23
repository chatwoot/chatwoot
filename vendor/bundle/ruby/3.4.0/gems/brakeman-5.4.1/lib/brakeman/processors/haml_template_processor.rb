require 'brakeman/processors/template_processor'

#Processes HAML templates.
class Brakeman::HamlTemplateProcessor < Brakeman::TemplateProcessor
  HAMLOUT = s(:call, nil, :_hamlout)
  HAML_BUFFER = s(:call, HAMLOUT, :buffer)
  HAML_HELPERS = s(:colon2, s(:const, :Haml), :Helpers)
  HAML_HELPERS2 = s(:colon2, s(:colon3, :Haml), :Helpers)
  JAVASCRIPT_FILTER = s(:colon2, s(:colon2, s(:const, :Haml), :Filters), :Javascript)
  COFFEE_FILTER = s(:colon2, s(:colon2, s(:const, :Haml), :Filters), :Coffee)
  ATTRIBUTE_BUILDER = s(:colon2, s(:colon3, :Haml), :AttributeBuilder)

  def initialize *args
    super
    @javascript = false
  end

  #Processes call, looking for template output
  def process_call exp
    exp = process_default exp

    if buffer_append? exp
      output = normalize_output(exp.first_arg)
      res = get_pushed_value(output)
    end

    res or exp
  end

  # _haml_out.buffer << ...
  def buffer_append? exp
    call? exp and
      exp.target == HAML_BUFFER and
      exp.method == :<<
  end

  PRESERVE_METHODS = [:find_and_preserve, :preserve]

  def find_and_preserve? exp
    call? exp and
      PRESERVE_METHODS.include?(exp.method) and
      exp.first_arg
  end

  #If inside an output stream, only return the final expression
  def process_block exp
    exp = exp.dup
    exp.shift

    exp.map! do |e|
      res = process e
      if res.empty?
        nil
      else
        res
      end
    end

    Sexp.new(:rlist).concat(exp).compact
  end

  #HAML likes to put interpolated values into _hamlout.push_text
  #but we want to handle those individually
  def build_output_from_push_text exp, default = :output
    if string_interp? exp
      exp.map! do |e|
        if sexp? e
          if node_type? e, :evstr and e[1]
            e = e.value
          end

          get_pushed_value e, default
        else
          e
        end
      end
    end
  end

  ESCAPE_METHODS = [
    :html_escape,
    :html_escape_without_haml_xss,
    :escape_once,
    :escape_once_without_haml_xss
  ]

  def get_pushed_value exp, default = :output
    return exp unless sexp? exp

    case exp.node_type
    when :format
      exp.node_type = :output
      @current_template.add_output exp
      exp
    when :format_escaped
      exp.node_type = :escaped_output
      @current_template.add_output exp
      exp
    when :str, :ignore, :output, :escaped_output
      exp
    when :block, :rlist
      exp.map! { |e| get_pushed_value(e, default) }
    when :dstr
      build_output_from_push_text(exp, default)
    when :if
      clauses = [get_pushed_value(exp.then_clause, default), get_pushed_value(exp.else_clause, default)].compact

      if clauses.length > 1
        s(:or, *clauses).line(exp.line)
      else
        clauses.first
      end
    when :call
      if exp.method == :to_s or exp.method == :strip
        get_pushed_value(exp.target, default)
      elsif haml_helpers? exp.target and ESCAPE_METHODS.include? exp.method
        get_pushed_value(exp.first_arg, :escaped_output)
      elsif @javascript and (exp.method == :j or exp.method == :escape_javascript) # TODO: Remove - this is not safe
        get_pushed_value(exp.first_arg, :escaped_output)
      elsif find_and_preserve? exp or fix_textareas? exp
        get_pushed_value(exp.first_arg, default)
      elsif raw? exp
        get_pushed_value(exp.first_arg, :output)
      elsif hamlout_attributes? exp
        ignore # ignore _hamlout.attributes calls
      elsif exp.target.nil? and exp.method == :render
        #Process call to render()
        exp.arglist = process exp.arglist
        make_render_in_view exp
      elsif exp.method == :render_with_options
        if exp.target == JAVASCRIPT_FILTER or exp.target == COFFEE_FILTER
          @javascript = true
        end

        get_pushed_value(exp.first_arg, default)
        @javascript = false
      elsif haml_attribute_builder? exp
        ignore # probably safe... seems escaped by default?
      else
        add_output exp, default
      end
    else
      add_output exp, default
    end
  end

  def haml_helpers? exp
    # Sometimes its Haml::Helpers and
    # sometimes its ::Haml::Helpers
    exp == HAML_HELPERS or
      exp == HAML_HELPERS2
  end

  def hamlout_attributes? exp
    call? exp and
      exp.target == HAMLOUT and
      exp.method == :attributes
  end

  def haml_attribute_builder? exp
    call? exp and
      exp.target == ATTRIBUTE_BUILDER and
      exp.method == :build
  end

  def fix_textareas? exp
    call? exp and
      exp.target == HAMLOUT and
      exp.method == :fix_textareas! 
  end

  def raw? exp
    call? exp and
      exp.method == :raw
  end
end
