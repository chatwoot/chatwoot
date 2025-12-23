# encoding: UTF-8

require 'pry'
require 'pry-rails/version'

if defined?(Rails) && !ENV['DISABLE_PRY_RAILS']
  require 'pry-rails/railtie'
  require 'pry-rails/commands'
  require 'pry-rails/model_formatter'
  require 'pry-rails/prompt'
end
