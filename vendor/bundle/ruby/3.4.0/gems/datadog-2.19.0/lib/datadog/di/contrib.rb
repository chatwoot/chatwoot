# frozen_string_literal: true

require_relative '../core/contrib/rails/utils'

module Datadog
  module DI
    module Contrib
      module_function def load_now_or_later
        if Datadog::Core::Contrib::Rails::Utils.railtie_supported?
          Datadog.logger.debug('di: loading contrib/railtie')
          require_relative 'contrib/railtie'
        else
          load_now
        end
      end

      # This method can be called more than once, to attempt to load
      # DI components that depend on third-party libraries after additional
      # dependencies are loaded (or potentially loaded).
      module_function def load_now
        if defined?(ActiveRecord::Base)
          Datadog.logger.debug('di: loading contrib/active_record')
          require_relative 'contrib/active_record'
        end
      end
    end
  end
end
