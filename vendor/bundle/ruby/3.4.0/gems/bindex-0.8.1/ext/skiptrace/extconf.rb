case RUBY_ENGINE
when "ruby"
  require "mkmf"

  $CFLAGS << " -Wall"
  $CFLAGS << " -g3 -O0" if ENV["DEBUG"]

  create_makefile("skiptrace/internal/cruby")
else
  IO.write(File.expand_path("../Makefile", __FILE__), <<-END)
    all install static install-so install-rb: Makefile
    .PHONY: all install static install-so install-rb
    .PHONY: clean clean-so clean-static clean-rb
  END
end
