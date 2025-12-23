require 'minitest/autorun'
require 'config/environment'

# Pry testing stuff (taken from Pry itself)

Pry.color = false

def redirect_pry_io(new_in, new_out = StringIO.new)
  old_in  = Pry.input
  old_out = Pry.output

  Pry.input  = new_in
  Pry.output = new_out

  begin
    yield
  ensure
    Pry.input  = old_in
    Pry.output = old_out
  end
end

def mock_pry(*args)
  binding = args.first.is_a?(Binding) ? args.shift : binding()
  input   = StringIO.new(args.join("\n"))
  output  = StringIO.new

  redirect_pry_io(input, output) do
    Pry.start(binding, :hooks => Pry::Hooks.new)
  end

  output.string
end
