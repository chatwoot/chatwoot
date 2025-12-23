require 'shoulda/matchers/configuration'
require 'shoulda/matchers/doublespeak'
require 'shoulda/matchers/error'
require 'shoulda/matchers/independent'
require 'shoulda/matchers/integrations'
require 'shoulda/matchers/matcher_context'
require 'shoulda/matchers/rails_shim'
require 'shoulda/matchers/util'
require 'shoulda/matchers/version'
require 'shoulda/matchers/warn'

require 'shoulda/matchers/action_controller'
require 'shoulda/matchers/active_model'
require 'shoulda/matchers/active_record'
require 'shoulda/matchers/routing'

module Shoulda
  module Matchers
    class << self
      # @private
      attr_accessor :assertion_exception_class
    end
  end
end
