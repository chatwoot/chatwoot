class PryRails::ShowRoutes < Pry::ClassCommand
  match 'show-routes'
  group 'Rails'
  description 'Show all routes in match order.'
  banner <<-BANNER
    Usage: show-routes [-G]
    show-routes displays the current Rails app's routes.
  BANNER

  def options(opt)
    opt.on :G, "grep", "Filter output by regular expression",
           :argument => true,
           :as => Array
  end

  def process
    Rails.application.reload_routes!
    all_routes = Rails.application.routes.routes

    formatted =
      if Rails::VERSION::MAJOR >= 6
        process_rails_6_and_higher(all_routes)
      elsif Rails::VERSION::MAJOR == 4 || Rails::VERSION::MAJOR == 5
        process_rails_4_and_5(all_routes)
      elsif Rails::VERSION::MAJOR >= 3 && Rails::VERSION::MINOR >= 2
        process_rails_3_2(all_routes)
      else
        process_rails_3_0_and_3_1(all_routes)
      end

    output.puts grep_routes(formatted).join("\n")
  end

  # Takes an array of lines. Returns a list filtered by the conditions in
  # `opts[:G]`.
  def grep_routes(formatted)
    return formatted unless opts[:G]
    grep_opts = opts[:G]

    grep_opts.reduce(formatted) do |lines, pattern|
      lines.grep(Regexp.new(pattern))
    end
  end

  # Cribbed from https://github.com/rails/rails/blob/3-1-stable/railties/lib/rails/tasks/routes.rake
  def process_rails_3_0_and_3_1(all_routes)
    routes = all_routes.collect do |route|
      reqs = route.requirements.dup
      reqs[:to] = route.app unless route.app.class.name.to_s =~ /^ActionDispatch::Routing/
        reqs = reqs.empty? ? "" : reqs.inspect

      {:name => route.name.to_s, :verb => route.verb.to_s, :path => route.path, :reqs => reqs}
    end

    # Skip the route if it's internal info route
    routes.reject! { |r| r[:path] =~ %r{/rails/info/properties|^/assets} }

    name_width = routes.map{ |r| r[:name].length }.max
    verb_width = routes.map{ |r| r[:verb].length }.max
    path_width = routes.map{ |r| r[:path].length }.max

    routes.map do |r|
      "#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:path].ljust(path_width)} #{r[:reqs]}"
    end
  end

  def process_rails_3_2(all_routes)
    require 'rails/application/route_inspector'

    Rails::Application::RouteInspector.new.format(all_routes)
  end

  def process_rails_4_and_5(all_routes)
    require 'action_dispatch/routing/inspector'

    ActionDispatch::Routing::RoutesInspector.
      new(all_routes).
      format(ActionDispatch::Routing::ConsoleFormatter.new).
      split(/\n/)
  end

  def process_rails_6_and_higher(all_routes)
    require 'action_dispatch/routing/inspector'

    ActionDispatch::Routing::RoutesInspector.
      new(all_routes).
      format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new).
      split(/\n/)
  end

  PryRails::Commands.add_command(self)
end
