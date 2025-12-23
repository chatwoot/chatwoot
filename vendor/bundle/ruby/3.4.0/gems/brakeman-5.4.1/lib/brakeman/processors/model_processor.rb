require 'brakeman/processors/base_processor'
require 'brakeman/processors/lib/module_helper'
require 'brakeman/tracker/model'

#Processes models. Puts results in tracker.models
class Brakeman::ModelProcessor < Brakeman::BaseProcessor
  include Brakeman::ModuleHelper

  def initialize tracker
    super
    @current_class = nil
    @current_method = nil
    @current_module = nil
    @visibility = :public
    @current_file = nil
  end

  #Process model source
  def process_model src, current_file = @current_file
    @current_file = current_file
    process src
  end

  #s(:class, NAME, PARENT, BODY)
  def process_class exp
    name = class_name(exp.class_name)

    #If inside an inner class we treat it as a library.
    if @current_class
      Brakeman.debug "[Notice] Treating inner class as library: #{name}"
      Brakeman::LibraryProcessor.new(@tracker).process_library exp, @current_file
      return exp
    end

    handle_class exp, @tracker.models, Brakeman::Model
  end

  def process_module exp
    handle_module exp, Brakeman::Model
  end

  #Handle calls outside of methods,
  #such as include, attr_accessible, private, etc.
  def process_call exp
    return exp unless @current_class
    return exp if process_call_defn? exp

    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method
    first_arg = exp.first_arg

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil?
      if first_arg.nil?
        case method
        when :private, :protected, :public
          @visibility = method
        when :attr_accessible
          @current_class.set_attr_accessible
        else
          #??
        end
      else
        case method
        when :include
          @current_class.add_include class_name(first_arg) if @current_class
        when :attr_accessible
          @current_class.set_attr_accessible exp
        when :attr_protected
          @current_class.set_attr_protected exp
        when :enum
          add_enum_method exp
        else
          if @current_class
            @current_class.add_option method, exp
          end
        end
      end

      exp
    else
      call = make_call target, method, process_all!(exp.args)
      call.line(exp.line)
      call
    end
  end

  def add_enum_method call
    arg = call.first_arg
    return unless hash? arg
    return unless symbol? arg[1]

    enum_name = arg[1].value # first key
    enums = arg[2] # first value
    enums_name = pluralize(enum_name.to_s).to_sym

    call_line = call.line

    if hash? enums
      enum_values = enums
    elsif array? enums
      # Build hash for enum values like Rails does
      enum_values = s(:hash).line(call_line)

      enums.each_sexp.with_index do |v, index|
        enum_values << v
        enum_values << s(:lit, index).line(call_line)
      end
    end

    enum_method = s(:defn, enum_name, s(:args), safe_literal(call_line))
    enums_method = s(:defs, s(:self), enums_name, s(:args), enum_values)

    @current_class.add_method :public, enum_name, enum_method, @current_file
    @current_class.add_method :public, enums_name, enums_method, @current_file
  end
end
