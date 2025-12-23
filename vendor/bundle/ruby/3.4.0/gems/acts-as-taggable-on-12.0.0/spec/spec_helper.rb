begin
  require 'byebug'
rescue LoadError
end
$LOAD_PATH << '.' unless $LOAD_PATH.include?('.')
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'logger'

require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)
I18n.enforce_available_locales = true
require 'rails'
require 'rspec/its'
require 'barrier'
require 'database_cleaner'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end
