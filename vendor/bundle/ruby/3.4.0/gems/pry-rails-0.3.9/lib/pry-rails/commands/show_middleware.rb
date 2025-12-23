class PryRails::ShowMiddleware < Pry::ClassCommand
  match 'show-middleware'
  group 'Rails'
  description 'Show all middleware (that Rails knows about).'
  banner <<-BANNER
    Usage: show-middleware [-G]

    show-middleware shows the Rails app's middleware.

    If this pry REPL is attached to a Rails server, the entire middleware
    stack is displayed.  Otherwise, only the middleware Rails knows about is
    printed.
  BANNER

  def options(opt)
    opt.on :G, "grep", "Filter output by regular expression", :argument => true
  end

  def process
    # assumes there is only one Rack::Server instance
    server = nil
    ObjectSpace.each_object(Rack::Server) do |object|
      server = object
    end

    middlewares = []

    if server
      stack = server.instance_variable_get("@wrapped_app")
      middlewares << stack.class.to_s

      while stack.instance_variable_defined?("@app") do
        stack = stack.instance_variable_get("@app")
        # Rails 3.0 uses the Application class rather than the application
        # instance itself, so we grab the instance.
        stack = Rails.application  if stack == Rails.application.class
        middlewares << stack.class.to_s  if stack != Rails.application
      end
    else
      middleware_names = Rails.application.middleware.map do |middleware|
        # After Rails 3.0, the middleware are wrapped in a special class
        # that responds to #name.
        if middleware.respond_to?(:name)
          middleware.name
        else
          middleware.inspect
        end
      end
      middlewares.concat middleware_names
    end
    middlewares << Rails.application.class.to_s
    print_middleware middlewares.grep(Regexp.new(opts[:G] || "."))
  end

  def print_middleware(middlewares)
    middlewares.each do |middleware|
      string = if middleware == Rails.application.class.to_s
        "run #{middleware}.routes"
      else
        "use #{middleware}"
      end
      output.puts string
    end
  end

  PryRails::Commands.add_command(self)
end
