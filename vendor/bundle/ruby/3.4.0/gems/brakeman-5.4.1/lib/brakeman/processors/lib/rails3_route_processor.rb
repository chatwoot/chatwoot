require 'brakeman/processors/lib/basic_processor'

#Processes the Sexp from routes.rb. Stores results in tracker.routes.
#
#Note that it is only interested in determining what methods on which
#controllers are used as routes, not the generated URLs for routes.
class Brakeman::Rails3RoutesProcessor < Brakeman::BasicProcessor
  include Brakeman::RouteHelper

  attr_reader :map, :nested, :current_controller

  def initialize tracker
    super
    @map = Sexp.new(:lvar, :map)
    @nested = nil  #used for identifying nested targets
    @prefix = [] #Controller name prefix (a module name, usually)
    @current_controller = nil
    @with_options = nil #For use inside map.with_options
    @controller_block = false
    @current_file = "config/routes.rb"
  end

  def process_routes exp
    process Brakeman::AliasProcessor.new.process_safely(exp, nil, @current_file)
  end

  def process_call exp
    case exp.method
    when :resources
      process_resources exp
    when :resource
      process_resource exp
    when :root
      process_root exp
    when :member
      process_default exp
    when :get, :put, :post, :delete
      process_verb exp
    when :match
      process_match exp
    else
      exp
    end
  end

  def process_iter exp
    case exp.block_call.method
    when :namespace
      process_namespace exp
    when :resource
      process_resource_block exp
    when :resources
      process_resources_block exp
    when :scope
      process_scope_block exp
    when :controller
      process_controller_block exp
    else
      process_default exp
    end
  end

  def process_namespace exp
    arg = exp.block_call.first_arg
    return exp unless symbol? arg or string? arg 

    name = arg.value
    block = exp.block

    @prefix << camelize(name)

    process block

    @prefix.pop

    exp
  end

  #TODO: Need test for this
  def process_root exp
    return exp unless hash? exp.first_arg

    if value = hash_access(exp.first_arg, :to)
      if string? value
        add_route_from_string value
      end
    end

    exp
  end

  def process_match exp
    first_arg = exp.first_arg
    second_arg = exp.second_arg
    last_arg = exp.last_arg

    if string? first_arg

      matcher = first_arg.value
      if matcher == ':controller(/:action(/:id(.:format)))' or
        matcher.include? ':controller' and action_route?(matcher)  #Default routes
        @tracker.routes[:allow_all_actions] = first_arg
        return exp
      elsif action_route?(first_arg)
          if hash? second_arg and controller_name = hash_access(second_arg, :controller)
            loose_action(controller_name, "matched") #TODO: Parse verbs
          end
      elsif second_arg.nil? and in_controller_block? and not matcher.include? ":"
        add_route matcher
      end
    end

    if hash? last_arg
      hash_iterate last_arg do |k, v|
        if string? k
          if string? v
            add_route_from_string v
          elsif in_controller_block? and symbol? v
            add_route v
          end
        elsif symbol? k
         case k.value
         when :action
          if string? v
            add_route_from_string v
          else
            add_route v
          end

         when :to
           if string? v
             add_route_from_string v[1]
           elsif in_controller_block? and symbol? v
             add_route v
           end
         end
        end
      end
    end

    @current_controller = nil unless in_controller_block?
    exp
  end

  def add_route_from_string value
    value = value[1] if string? value

    controller, action = extract_action value

    if action
      add_route action, controller
    elsif in_controller_block?
      add_route value
    end
  end

  def process_verb exp
    first_arg = exp.first_arg
    second_arg = exp.second_arg

    if symbol? first_arg and not hash? second_arg
      add_route first_arg
    elsif hash? second_arg
      hash_iterate second_arg do |k, v|
        if symbol? k and k.value == :to
          if string? v
            add_route_from_string v
          elsif in_controller_block? and symbol? v
            add_route v
          end
        elsif action_route?(first_arg)
          if hash? second_arg and controller_name = hash_access(second_arg, :controller)
            loose_action(controller_name, exp.method)
          end
        end
      end
    elsif string? first_arg
      if first_arg.value.include? ':controller' and action_route?(first_arg) #Default routes
        @tracker.routes[:allow_all_actions] = first_arg
      end

      route = first_arg.value.split "/"
      if route.length != 2
        add_route route[0]
      else
        add_route route[1], route[0]
      end
    else hash? first_arg
      hash_iterate first_arg do |k, v|
        if string? k
          if string? v
            add_route_from_string v
          elsif in_controller_block?
            add_route v
          end
        end
      end
    end

    @current_controller = nil unless in_controller_block?
    exp
  end

  def process_resources exp
    first_arg = exp.first_arg
    second_arg = exp.second_arg

    return exp unless symbol? first_arg or string? first_arg

    if second_arg and second_arg.node_type == :hash
      self.current_controller = first_arg.value
      #handle hash
      add_resources_routes
    elsif exp.args.all? { |s| symbol? s }
      exp.each_arg do |s|
        self.current_controller = s.value
        add_resources_routes
      end
    end

    @current_controller = nil unless in_controller_block?
    exp
  end

  def process_resource exp
    #Does resource even take more than one controller name?
    exp.each_arg do |s|
      if symbol? s
        self.current_controller = pluralize(s.value.to_s)
        add_resource_routes
      else
        #handle something else, like options
        #or something?
      end
    end

    @current_controller = nil unless in_controller_block?
    exp
  end

  def process_resources_block exp
    in_controller_block do
      process_resources exp.block_call
      process exp.block
    end

    @current_controller = nil
    exp
  end

  def process_resource_block exp
    in_controller_block do
      process_resource exp.block_call
      process exp.block
    end

    @current_controller = nil
    exp
  end

  def process_scope_block exp
    #How to deal with options?
    process exp.block
    exp
  end

  def process_controller_block exp
    if string? exp or symbol? exp
      self.current_controller = exp.block_call.first_arg.value

      in_controller_block do
        process exp[-1] if exp[-1]
      end

      @current_controller = nil
    end

    exp
  end

  def extract_action str
    str.split "#"
  end

  def in_controller_block?
    @controller_block
  end

  def in_controller_block
    prev_block = @controller_block
    @controller_block = true
    yield
    @controller_block = prev_block
  end

  def action_route? arg
    if string? arg
      arg = arg.value
    end

    arg.is_a? String and (arg.include? ":action" or arg.include? "*action")
  end

  def loose_action controller_name, verb = "any"
    self.current_controller = controller_name.value
    @tracker.routes[@current_controller] = [:allow_all_actions, {:allow_verb => verb}]
  end
end
