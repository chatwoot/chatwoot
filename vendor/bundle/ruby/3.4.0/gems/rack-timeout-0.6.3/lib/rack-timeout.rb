require_relative "rack/timeout/base"
require_relative "rack/timeout/rails" if defined?(Rails) && Rails::VERSION::MAJOR >= 3
