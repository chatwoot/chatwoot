require 'rails'
require 'selectize-rails/version'

module Selectize
  module Rails
    if ::Rails.version < '3.1'
      require 'selectize-rails/railtie'
    else
      require 'selectize-rails/engine'
    end
  end
end
