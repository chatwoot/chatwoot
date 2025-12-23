# frozen_string_literal: true

module Bullet
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc <<~DESC
        Description:
            Enable bullet in development/test for your application.
      DESC

      def enable_in_development
        environment(nil, env: 'development') do
          <<~FILE
            config.after_initialize do
              Bullet.enable        = true
              Bullet.alert         = true
              Bullet.bullet_logger = true
              Bullet.console       = true
              Bullet.rails_logger  = true
              Bullet.add_footer    = true
            end

          FILE
        end

        say 'Enabled bullet in config/environments/development.rb'
      end

      def enable_in_test
        return unless yes?('Would you like to enable bullet in test environment? (y/n)')

        environment(nil, env: 'test') do
          <<~FILE
            config.after_initialize do
              Bullet.enable        = true
              Bullet.bullet_logger = true
              Bullet.raise         = true # raise an error if n+1 query occurs
            end

          FILE
        end

        say 'Enabled bullet in config/environments/test.rb'
      end
    end
  end
end
