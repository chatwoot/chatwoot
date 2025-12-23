require 'brakeman/processors/lib/basic_processor'

#Processes the Sexp from routes.rb. Stores results in tracker.routes.
#
#Note that it is only interested in determining what methods on which
#controllers are used as routes, not the generated URLs for routes.
class Brakeman::Rails2RoutesProcessor < Brakeman::BasicProcessor
  include Brakeman::RouteHelper

  attr_reader :map, :nested, :current_controller

  def initialize tracker
    super
    @map = Sexp.new(:lvar, :map)
    @nested = nil  #used for identifying nested targets
    @prefix = [] #Controller name prefix (a module name, usually)
    @current_controller = nil
    @with_options = nil #For use inside map.with_options
    @current_file = "config/routes.rb"
  end

  #Call this with parsed route file information.
  #
  #This method first calls RouteAliasProcessor#process_safely on the +exp+,
  #so it does not modify the +exp+.
  def process_routes exp
    process Brakeman::RouteAliasProcessor.new.process_safely(exp, nil, @current_file)
  end

  #Looking for mapping of routes
  def process_call exp
    target = exp.target

    if target == map or (not target.nil? and target == nested)
      process_map exp
    else
      process_default exp
    end

    exp
  end

  #Process a map.something call
  #based on the method used
  def process_map exp
    args = exp.args

    case exp.method
    when :resource
      process_resource args
    when :resources
      process_resources args
    when :connect, :root
      process_connect args
    else
      process_named_route args
    end

    exp
  end

  #Look for map calls that take a block.
  #Otherwise, just do the default processing.
  def process_iter exp
    target = exp.block_call.target

    if target == map or target == nested
      method = exp.block_call.method
      case method
      when :namespace
        process_namespace exp
      when :resources, :resource
        process_resources exp.block_call.args
        process_default exp.block if exp.block
      when :with_options
        process_with_options exp
      end
      exp
    else
      process_default exp
    end
  end

  #Process
  # map.resources :x, :controller => :y, :member => ...
  #etc.
  def process_resources exp
    controller = check_for_controller_name exp
    if controller
      self.current_controller = controller
      process_resource_options exp[-1]
    else
      exp.each do |argument|
        if node_type? argument, :lit
          self.current_controller = exp.first.value
          add_resources_routes
          process_resource_options exp.last
        end
      end
    end
  end

  #Process all the options that might be in the hash passed to
  #map.resource, et al.
  def process_resource_options exp
    if exp.nil? and @with_options
      exp = @with_options
    elsif @with_options
      exp = exp.concat @with_options[1..-1]
    end
    return unless exp.node_type == :hash

    hash_iterate(exp) do |option, value|
      case option[1]
      when :controller, :requirements, :singular, :path_prefix, :as,
        :path_names, :shallow, :name_prefix, :member_path, :nested_member_path,
        :belongs_to, :conditions, :active_scaffold
        #should be able to skip
      when :collection, :member, :new
        process_collection value
      when :has_one
        save_controller = current_controller
        process_resource value[1..-1] #Verify this is proper behavior
        self.current_controller = save_controller
      when :has_many
        save_controller = current_controller
        process_resources value[1..-1]
        self.current_controller = save_controller
      when :only
        process_option_only value
      when :except
        process_option_except value
      else
        Brakeman.notify "[Notice] Unhandled resource option, please report: #{option}"
      end
    end
  end

  #Process route option :only => ...
  def process_option_only exp
    routes = @tracker.routes[@current_controller]
    [:index, :new, :create, :show, :edit, :update, :destroy].each do |r|
      routes.delete r
    end

    if exp.node_type == :array
      exp[1..-1].each do |e|
        routes << e.value
      end
    end
  end

  #Process route option :except => ...
  def process_option_except exp
    return unless exp.node_type == :array
    routes = @tracker.routes[@current_controller]

    exp[1..-1].each do |e|
      routes.delete e.value
    end
  end

  #  map.resource :x, ..
  def process_resource exp
    controller = check_for_controller_name exp
    if controller
      self.current_controller = controller
      process_resource_options exp.last
    else
      exp.each do |argument|
        if node_type? argument, :lit
          self.current_controller = pluralize(exp.first.value.to_s)
          add_resource_routes
          process_resource_options exp.last
        end
      end
    end
  end

  #Process
  # map.connect '/something', :controller => 'blah', :action => 'whatever'
  def process_connect exp
    return if exp.empty?

    controller = check_for_controller_name exp
    self.current_controller = controller if controller

    #Check for default route
    if string? exp.first
      if exp.first.value == ":controller/:action/:id"
        @tracker.routes[:allow_all_actions] = exp.first
      elsif exp.first.value.include? ":action"
        @tracker.routes[@current_controller] = [:allow_all_actions, exp.line]
        return
      end
    end

    #This -seems- redundant, but people might connect actions
    #to a controller which already allows them all
    return if @tracker.routes[@current_controller].is_a? Array and @tracker.routes[@current_controller][0] == :allow_all_actions

    exp.last.each_with_index do |e,i|
      if symbol? e and e.value == :action
        action = exp.last[i + 1]

        if node_type? action, :lit
          @tracker.routes[@current_controller] << action.value.to_sym
        end

        return
      end
    end
  end

  # map.with_options :controller => 'something' do |something|
  #   something.resources :blah
  # end
  def process_with_options exp
    @with_options = exp.block_call.last_arg
    @nested = Sexp.new(:lvar, exp.block_args.value)

    self.current_controller = check_for_controller_name exp.block_call.args

    #process block
    process exp.block

    @with_options = nil
    @nested = nil
  end

  # map.namespace :something do |something|
  #   something.resources :blah
  # end
  def process_namespace exp
    call = exp.block_call
    formal_args = exp.block_args
    block = exp.block

    @prefix << camelize(call.first_arg.value)

    if formal_args
      @nested = Sexp.new(:lvar, formal_args.value)
    end

    process block

    @prefix.pop
  end

  # map.something_abnormal '/blah', :controller => 'something', :action => 'wohoo'
  def process_named_route exp
    process_connect exp
  end

  #Process collection option
  # :collection => { :some_action => :http_actions }
  def process_collection exp
    return unless exp.node_type == :hash
    routes = @tracker.routes[@current_controller]

    hash_iterate(exp) do |action, _type|
      routes << action.value
    end
  end

  private

  #Checks an argument list for a hash that has a key :controller.
  #If it does, returns the value.
  #
  #Otherwise, returns nil.
  def check_for_controller_name args
    args.each do |a|
      if hash? a and value = hash_access(a, :controller)
        return value.value if string? value or symbol? value
      end
    end

    nil
  end
end

#This is for a really specific case where a hash is used as arguments
#to one of the map methods.
class Brakeman::RouteAliasProcessor < Brakeman::AliasProcessor

  #This replaces
  # { :some => :hash }.keys
  #with
  # [:some]
  def process_call exp
    process_default exp

    if hash? exp.target and exp.method == :keys
      keys = get_keys exp.target
      exp.clear
      keys.each_with_index do |e,i|
        exp[i] = e
      end
    end
    exp
  end

  #Returns an array Sexp containing the keys from the hash
  def get_keys hash
    keys = Sexp.new(:array)
    hash_iterate(hash) do |key, _value|
      keys << key
    end

    keys
  end
end
