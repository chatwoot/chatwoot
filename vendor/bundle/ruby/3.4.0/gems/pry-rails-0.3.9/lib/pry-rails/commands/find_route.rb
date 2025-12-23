class PryRails::FindRoute < Pry::ClassCommand
  match 'find-route'
  group 'Rails'
  description 'See which URLs match a given Controller.'
  banner <<-BANNER
    Usage: find-route <controller>

    Returns the URL(s) that match a given controller or controller action.

    find-route MyController#show  #=> The URL that matches the MyController show action
    find-route MyController       #=> All the URLs that hit MyController
    find-route Admin              #=> All the URLs that hit the Admin namespace
    find-route Com                #=> All the URLS whose controller regex matches /Comm/, e.g CommentsController
  BANNER

  def process(controller)
    controller_string = controller.to_s
    if single_action?(controller_string)
      single_action(controller_string)
    else
      all_actions(controller_string)
    end
  end

  private

  def single_action(controller)
    show_routes { |route| route.defaults == controller_and_action_from(controller) }
  end

  def all_actions(controller)
    show_routes do |route|
      route.defaults[:controller].to_s =~ /#{normalize_controller_name(controller)}/
    end
  end

  def controller_and_action_from(controller_and_action)
    controller, action = controller_and_action.split("#")
    {controller: normalize_controller_name(controller), action: action}
  end

  def routes
    Rails.application.routes.routes
  end

  def normalize_controller_name(controller)
    controller.underscore.chomp('_controller')
  end

  def show_routes(&block)
    all_routes = routes.select(&block)
    if all_routes.any?
      grouped_routes = all_routes.group_by { |route| route.defaults[:controller] }
      result = grouped_routes.each_with_object("") do |(controller, routes), res|
        res << "Routes for " + text.bold(controller.to_s.camelize + "Controller") + "\n"
        res << "--\n"
        routes.each do |route|
          spec = route.path.is_a?(String) ? route.path : route.path.spec
          res << "#{route.defaults[:action]} #{text.bold(verb_for(route))} #{spec}  #{route_helper(route.name)}" + "\n"
        end
        res << "\n"
      end
      stagger_output result
    else
      output.puts "No routes found."
    end
  end

  def route_helper(name)
    name && "[#{name}]"
  end

  def verb_for(route)
    %w(GET PUT POST PATCH DELETE).find { |v| route.verb === v }
  end

  def single_action?(controller)
    controller =~ /#/
  end

  PryRails::Commands.add_command(self)
end

PryRails::Commands.alias_command "find-routes", "find-route"
