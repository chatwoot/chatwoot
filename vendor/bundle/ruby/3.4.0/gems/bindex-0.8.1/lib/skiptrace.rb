case RUBY_ENGINE
when 'rbx'
  require 'skiptrace/internal/rubinius'
when 'jruby'
  require 'skiptrace/internal/jruby'
when 'ruby'
  require 'skiptrace/internal/cruby'
end

require 'skiptrace/location'
require 'skiptrace/binding_locations'
require 'skiptrace/binding_ext'
require 'skiptrace/exception_ext'
require 'skiptrace/version'
