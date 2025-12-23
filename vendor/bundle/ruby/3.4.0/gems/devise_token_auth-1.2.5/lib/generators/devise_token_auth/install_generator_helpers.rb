module DeviseTokenAuth
  module InstallGeneratorHelpers
    class << self
      def included(mod)
        mod.class_eval do
          source_root File.expand_path('templates', __dir__)

          argument :user_class, type: :string, default: 'User'
          argument :mount_path, type: :string, default: 'auth'

          def create_initializer_file
            copy_file('devise_token_auth.rb', 'config/initializers/devise_token_auth.rb')
          end

          def include_controller_concerns
            fname = 'app/controllers/application_controller.rb'
            line  = 'include DeviseTokenAuth::Concerns::SetUserByToken'

            if File.exist?(File.join(destination_root, fname))
              if parse_file_for_line(fname, line)
                say_status('skipped', 'Concern is already included in the application controller.')
              elsif is_rails_api?
                inject_into_file fname, after: "class ApplicationController < ActionController::API\n" do <<-'RUBY'
        include DeviseTokenAuth::Concerns::SetUserByToken
                RUBY
                end
              else
                inject_into_file fname, after: "class ApplicationController < ActionController::Base\n" do <<-'RUBY'
        include DeviseTokenAuth::Concerns::SetUserByToken
                RUBY
                end
              end
            else
              say_status('skipped', "app/controllers/application_controller.rb not found. Add 'include DeviseTokenAuth::Concerns::SetUserByToken' to any controllers that require authentication.")
            end
          end

          def add_route_mount
            f    = 'config/routes.rb'
            str  = "mount_devise_token_auth_for '#{user_class}', at: '#{mount_path}'"

            if File.exist?(File.join(destination_root, f))
              line = parse_file_for_line(f, 'mount_devise_token_auth_for')

              if line
                existing_user_class = true
              else
                line = 'Rails.application.routes.draw do'
                existing_user_class = false
              end

              if parse_file_for_line(f, str)
                say_status('skipped', "Routes already exist for #{user_class} at #{mount_path}")
              else
                insert_after_line(f, line, str)

                if existing_user_class
                  scoped_routes = ''\
                    "as :#{user_class.underscore} do\n"\
                    "    # Define routes for #{user_class} within this block.\n"\
                    "  end\n"
                  insert_after_line(f, str, scoped_routes)
                end
              end
            else
              say_status('skipped', "config/routes.rb not found. Add \"mount_devise_token_auth_for '#{user_class}', at: '#{mount_path}'\" to your routes file.")
            end
          end

          private

          def insert_after_line(filename, line, str)
            gsub_file filename, /(#{Regexp.escape(line)})/mi do |match|
              "#{match}\n  #{str}"
            end
          end

          def parse_file_for_line(filename, str)
            match = false

            File.open(File.join(destination_root, filename)) do |f|
              f.each_line do |line|
                match = line if line =~ /(#{Regexp.escape(str)})/mi
              end
            end
            match
          end

          def is_rails_api?
            fname = 'app/controllers/application_controller.rb'
            line = 'class ApplicationController < ActionController::API'
            parse_file_for_line(fname, line)
          end
        end
      end
    end
  end
end
