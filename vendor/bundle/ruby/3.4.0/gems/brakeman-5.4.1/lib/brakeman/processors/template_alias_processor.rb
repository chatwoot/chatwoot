require 'set'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/render_helper'
require 'brakeman/processors/lib/render_path'
require 'brakeman/tracker'

#Processes aliasing in templates.
#Handles calls to +render+.
class Brakeman::TemplateAliasProcessor < Brakeman::AliasProcessor
  include Brakeman::RenderHelper

  FORM_METHODS = Set[:form_for, :remote_form_for, :form_remote_for]

  def initialize tracker, template, called_from = nil
    super tracker
    @template = template
    @current_file = template.file
    @called_from = called_from
  end

  #Process template
  def process_template name, args, _, line = nil
    # Strip forward slash from beginning of template path.
    # This also happens in RenderHelper#process_template but
    # we need it here too to accurately avoid circular renders below.
    name = name.to_s.gsub(/^\//, "")

    if @called_from
      if @called_from.include_template? name
        Brakeman.debug "Skipping circular render from #{@template.name} to #{name}"
        return
      end

      super name, args, @called_from.dup.add_template_render(@template.name, line, @current_file), line
    else
      super name, args, Brakeman::RenderPath.new.add_template_render(@template.name, line, @current_file), line
    end
  end

  def process_lasgn exp
    if exp.lhs == :haml_temp or haml_capture? exp.rhs
      exp.rhs = process exp.rhs

      # Avoid propagating contents of block
      if node_type? exp.rhs, :iter
        new_exp = exp.dup
        new_exp.rhs = exp.rhs.block_call

        super new_exp

        exp # Still save the original, though
      else
        super exp
      end
    else
      super exp
    end
  end

  HAML_CAPTURE = [:capture, :capture_haml]

  def haml_capture? exp
    node_type? exp, :iter and
      call? exp.block_call and
      HAML_CAPTURE.include? exp.block_call.method
  end

  #Determine template name
  def template_name name
    if !name.to_s.include?('/') && @template.name.to_s.include?('/')
      name = "#{@template.name.to_s.match(/^(.*\/).*$/)[1]}#{name}"
    end
    name
  end

  UNKNOWN_MODEL_CALL = Sexp.new(:call, Sexp.new(:const, Brakeman::Tracker::UNKNOWN_MODEL), :new)
  FORM_BUILDER_CALL = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new)

  #Looks for form methods and iterating over collections of Models
  def process_iter exp
    process_default exp

    call = exp.block_call

    if call? call
      target = call.target
      method = call.method
      arg = exp.block_args.first_param
      block = exp.block

      #Check for e.g. Model.find.each do ... end
      if method == :each and arg and block and model = get_model_target(target)
        if arg.is_a? Symbol
          if model == target.target
            env[Sexp.new(:lvar, arg)] = Sexp.new(:call, model, :new)
          else
            env[Sexp.new(:lvar, arg)] = UNKNOWN_MODEL_CALL
          end

          process block if sexp? block
        end
      elsif FORM_METHODS.include? method
        if arg.is_a? Symbol
          env[Sexp.new(:lvar, arg)] = FORM_BUILDER_CALL

          process block if sexp? block
        end
      end
    end

    exp
  end

  COLLECTION_METHODS = [:all, :find, :select, :where]

  #Checks if +exp+ is a call to Model.all or Model.find*
  def get_model_target exp
    if call? exp
      target = exp.target

      if COLLECTION_METHODS.include? exp.method or exp.method.to_s[0,4] == "find"
        models = Set.new @tracker.models.keys
        name = class_name target
        return target if models.include?(name)
      end

      return get_model_target(target)
    end

    false
  end

  #Ignore `<<` calls on template variables which are used by the templating
  #library (HAML, ERB, etc.)
  def find_push_target exp
    if sexp? exp
      if exp.node_type == :lvar and (exp.value == :_buf or exp.value == :_erbout)
        return nil
      elsif exp.node_type == :ivar and exp.value == :@output_buffer
        return nil
      elsif exp.node_type == :call and call? exp.target and
        exp.target.method == :_hamlout and exp.method == :buffer

        return nil
      end
    end

    super
  end
end
