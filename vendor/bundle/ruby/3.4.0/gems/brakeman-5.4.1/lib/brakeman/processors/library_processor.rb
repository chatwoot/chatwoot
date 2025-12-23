require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/module_helper'
require 'brakeman/tracker/library'

#Process generic library and stores it in Tracker.libs
class Brakeman::LibraryProcessor < Brakeman::BaseProcessor
  include Brakeman::ModuleHelper

  def initialize tracker
    super
    @current_file = nil
    @alias_processor = Brakeman::AliasProcessor.new tracker
    @current_module = nil
    @current_class = nil
    @initializer_env = nil
  end

  def process_library src, current_file = @current_file
    @current_file = current_file
    process src
  end

  def process_class exp
    handle_class exp, @tracker.libs, Brakeman::Library
  end

  def process_module exp
    handle_module exp, Brakeman::Library
  end

  def process_defn exp
    if exp.method_name == :initialize
      @alias_processor.process_safely exp.body_list
      @initializer_env = @alias_processor.only_ivars
    elsif node_type? exp, :defn
      exp = @alias_processor.process_safely exp, @initializer_env
    else
      exp = @alias_processor.process exp
    end

    if @current_class
      exp.body = process_all! exp.body
      @current_class.add_method :public, exp.method_name, exp, @current_file
    elsif @current_module
      exp.body = process_all! exp.body
      @current_module.add_method :public, exp.method_name, exp, @current_file
    end

    exp
  end

  alias process_defs process_defn

  def process_call exp
    if process_call_defn? exp
      exp
    elsif @current_method.nil? and exp.target.nil? and (@current_class or @current_module)
      # Methods called inside class / module
      case exp.method
      when :include
        module_name = class_name(exp.first_arg)
        (@current_class || @current_module).add_include module_name
      end

      exp
    else
      process_default exp
    end
  end

  def process_iter exp
    res = process_default exp

    if node_type? res, :iter and call? exp.block_call # sometimes this changes after processing
      if exp.block_call.method == :included and (@current_module or @current_class)
        (@current_module || @current_class).options[:included] = res.block
      end
    end

    res
  end
end
