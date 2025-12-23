require 'skiptrace/internal/jruby_internals'

module Skiptrace
  java_import com.gsamokovarov.skiptrace.JRubyIntegration

  JRubyIntegration.setup(JRuby.runtime)
end
