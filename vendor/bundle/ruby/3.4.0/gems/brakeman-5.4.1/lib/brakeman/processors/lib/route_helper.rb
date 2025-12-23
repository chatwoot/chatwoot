module Brakeman::RouteHelper
  #Manage Controller prefixes
  #@prefix is an Array, but this method returns a string
  #suitable for prefixing onto a controller name.
  def prefix
    if @prefix.length > 0
      @prefix.join("::") << "::"
    else
      ''
    end
  end

  #Sets the controller name to a proper class name.
  #For example
  # self.current_controller = :session
  # @controller == :SessionController #true
  #
  #Also prepends the prefix if there is one set.
  def current_controller= name
    @current_controller = (prefix + camelize(name) + "Controller").to_sym
    @tracker.routes[@current_controller] ||= Set.new
  end

  #Add route to controller. If a controller is specified,
  #the current controller will be set to that controller.
  #If no controller is specified, uses current controller value.
  def add_route route, controller = nil
    if node_type? route, :str, :lit
      route = route.value
    end

    return unless route.is_a? String or route.is_a? Symbol

    if route.is_a? String and controller.nil? and route.include? ":controller"
      controller = ":controller"
    end

    route = route.to_sym

    if controller
      self.current_controller = controller
    end

    routes = @tracker.routes[@current_controller]
    
    if routes and not routes.include? :allow_all_actions
      routes << route
    end
  end

  #Add default routes
  def add_resources_routes
    existing_routes = @tracker.routes[@current_controller]

    unless existing_routes.is_a? Array and existing_routes.first == :allow_all_actions
      existing_routes.merge [:index, :new, :create, :show, :edit, :update, :destroy]
    end
  end

  #Add default routes minus :index
  def add_resource_routes
    existing_routes = @tracker.routes[@current_controller]

    unless existing_routes.is_a? Array and existing_routes.first == :allow_all_actions
      existing_routes.merge [:new, :create, :show, :edit, :update, :destroy]
    end
  end
end
