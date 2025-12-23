begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test"
  end
rescue LoadError
  # Don't care
end
