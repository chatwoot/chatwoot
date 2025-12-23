class PryRails::RecognizePath < Pry::ClassCommand
  match 'recognize-path'
  group 'Rails'
  description 'See which route matches a URL.'
  command_options argument_required: true
  banner <<-BANNER
    Usage: recognize-path <path> [-m|--method METHOD]

    Verifies that a given path is mapped to the right controller and action.

    recognize-path example.com
    recognize-path example.com -m post
  BANNER

  def options(opt)
    opt.on :m, :method, "Methods", :argument => true
  end

  def process(path)
    method = (opts.m? ? opts[:m] : :get)
    routes = Rails.application.routes

    begin
      info = routes.recognize_path("http://#{path}", :method => method)
    rescue ActionController::UnknownHttpMethod
      output.puts "Unknown HTTP method: #{method}"
    rescue ActionController::RoutingError => e
      output.puts e
    end

    output.puts Pry::Helpers::BaseHelpers.colorize_code(info)
  end

  PryRails::Commands.add_command(self)
end
