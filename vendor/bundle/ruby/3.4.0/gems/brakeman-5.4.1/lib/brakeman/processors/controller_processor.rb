require 'brakeman/processors/base_processor'
require 'brakeman/processors/lib/module_helper'
require 'brakeman/tracker/controller'

#Processes controller. Results are put in tracker.controllers
class Brakeman::ControllerProcessor < Brakeman::BaseProcessor
  include Brakeman::ModuleHelper

  FORMAT_HTML = Sexp.new(:call, Sexp.new(:lvar, :format), :html)

  def initialize tracker, current_file = nil
    super(tracker)
    @visibility = :public
    @current_file = current_file
    @concerns = Set.new
  end

  #Use this method to process a Controller
  def process_controller src, current_file = @current_file
    @current_file = current_file
    process src
  end

  #s(:class, NAME, PARENT, s(:scope ...))
  def process_class exp
    name = class_name(exp.class_name)
    parent = class_name(exp.parent_name)

    #If inside a real controller, treat any other classes as libraries.
    #But if not inside a controller already, then the class may include
    #a real controller, so we can't take this shortcut.
    if @current_class and @current_class.name.to_s.end_with? "Controller"
      Brakeman.debug "[Notice] Treating inner class as library: #{name}"
      Brakeman::LibraryProcessor.new(@tracker).process_library exp, @current_file
      return exp
    end

    if not name.to_s.end_with? "Controller"
      Brakeman.debug "[Notice] Adding noncontroller as library: #{name}"
      #Set the class to be a module in order to get the right namespacing.
      #Add class to libraries, in case it is needed later (e.g. it's used
      #as a parent class for a controller.)
      #However, still want to process it in this class, so have to set
      #@current_class to this not-really-a-controller thing.
      process_module exp, parent

      return exp
    end

    handle_class(exp, @tracker.controllers, Brakeman::Controller) do
      set_layout_name
    end

    exp
  end

  def process_module exp, parent = nil
    handle_module exp, Brakeman::Controller, parent
  end

  def process_concern concern_name
    return unless @current_class

    if mod = @tracker.find_class(concern_name)
      if mod.options[:included] and not @concerns.include? concern_name
        @concerns << concern_name
        process mod.options[:included].deep_clone
      end
    end
  end

  #Look for specific calls inside the controller
  def process_call exp
    return exp if process_call_defn? exp

    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method
    first_arg = exp.first_arg
    last_arg = exp.last_arg

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil? and @current_class
      if first_arg.nil? #No args
        case method
        when :private, :protected, :public
          @visibility = method
        when :protect_from_forgery
          @current_class.options[:protect_from_forgery] = true
        else
          #??
        end
      else
        case method
        when :include
          if @current_class
            concern = class_name(first_arg)
            @current_class.add_include concern
            process_concern concern
          end
        when :before_filter, :append_before_filter, :before_action, :append_before_action
          if node_type? exp.first_arg, :iter
            add_lambda_filter exp
          else
            @current_class.add_before_filter exp
          end
        when :prepend_before_filter, :prepend_before_action
          if node_type? exp.first_arg, :iter
            add_lambda_filter exp
          else
            @current_class.prepend_before_filter exp
          end
        when :skip_before_filter, :skip_filter, :skip_before_action, :skip_action_callback
          @current_class.skip_filter exp
        when :layout
          if string? last_arg
            #layout "some_layout"

            name = last_arg.value.to_s
            if @app_tree.layout_exists?(name)
              @current_class.layout = "layouts/#{name}"
            else
              Brakeman.debug "[Notice] Layout not found: #{name}"
            end
          elsif node_type? last_arg, :nil, :false
            #layout :false or layout nil
            @current_class.layout = false
          end
        else
          @current_class.add_option method, exp
        end
      end

      exp
    elsif target == nil and method == :render
      make_render exp
    elsif exp == FORMAT_HTML and context[1] != :iter
      #This is an empty call to
      # format.html
      #Which renders the default template if no arguments
      #Need to make more generic, though.
      call = Sexp.new :render, :default, @current_method
      call.line(exp.line)
      call
    else
      call = make_call target, method, process_all!(exp.args)
      call.line(exp.line)
      call
    end
  end

  #Look for before_filters and add fake ones if necessary
  def process_iter exp
    if @current_method.nil? and call? exp.block_call
      block_call_name = exp.block_call.method

      if block_call_name == :before_filter  or block_call_name == :before_action
        add_fake_filter exp
      else
        super
      end
    else
      super
    end
  end

  #Sets default layout for renders inside Controller
  def set_layout_name
    return if @current_class.layout

    name = underscore(@current_class.name.to_s.split("::")[-1].gsub("Controller", ''))

    #There is a layout for this Controller
    if @app_tree.layout_exists?(name)
      @current_class.layout = "layouts/#{name}"
    end
  end

  #This is to handle before_filter do |controller| ... end
  #
  #We build a new method and process that the same way as usual
  #methods and filters.
  def add_fake_filter exp
    unless @current_class
      Brakeman.debug "Skipping before_filter outside controller: #{exp}"
      return exp
    end

    filter_name = ("fake_filter" + rand.to_s[/\d+$/]).to_sym
    args = exp.block_call.arglist
    args.insert(1, Sexp.new(:lit, filter_name).line(exp.line))
    before_filter_call = make_call(nil, :before_filter, args).line(exp.line)

    if exp.block_args.length > 1
      block_variable = exp.block_args[1]
    else
      block_variable = :temp
    end

    if node_type? exp.block, :block
      block_inner = exp.block.sexp_body
    else
      block_inner = [exp.block]
    end

    #Build Sexp for filter method
    body = Sexp.new(:lasgn,
                    block_variable,
                    Sexp.new(:call, Sexp.new(:const, @current_class.name).line(exp.line), :new).line(exp.line)).line(exp.line)

    filter_method = Sexp.new(:defn, filter_name, Sexp.new(:args).line(exp.line), body).concat(block_inner).line(exp.line)

    vis = @visibility
    @visibility = :private
    process_defn filter_method
    @visibility = vis
    process before_filter_call
    exp
  end

  def add_lambda_filter exp
    # Convert into regular block call
    e = exp.dup
    lambda_node = e.delete_at(3)
    result = Sexp.new(:iter, e).line(e.line)

    # Add block arguments
    if node_type? lambda_node[2], :args
      result << lambda_node[2].last
    else
      result << s(:args)
    end

    # Add block contents
    if sexp? lambda_node[3]
      result << lambda_node[3]
    end

    add_fake_filter result
  end
end
