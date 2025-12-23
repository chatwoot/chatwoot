begin
  require 'rails/railtie'

  module Hashie
    class Railtie < Rails::Railtie
      # Set the Hashie.logger to use Rails.logger when used with rails.
      initializer 'hashie.configure_logger', after: 'initialize_logger' do
        Hashie.logger = Rails.logger
      end

      initializer 'hashie.patch_hash_except', after: 'load_active_support' do
        if Rails::VERSION::MAJOR >= 6
          require 'hashie/extensions/active_support/core_ext/hash'
          Hashie::Mash.send(:include, Hashie::Extensions::ActiveSupport::CoreExt::Hash)
        end
      end
    end
  end
rescue LoadError => e
  Hashie.logger.info("Hashie skipping railtie as #{e.message}")
end
