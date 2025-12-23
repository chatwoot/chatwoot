# frozen_string_literal: true

require_relative 'install_generator_helpers'

module DeviseTokenAuth
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    include DeviseTokenAuth::InstallGeneratorHelpers

    class_option :primary_key_type, type: :string, desc: 'The type for primary key'

    def copy_migrations
      if self.class.migration_exists?('db/migrate', "devise_token_auth_create_#{user_class.pluralize.gsub('::','').underscore}")
        say_status('skipped', "Migration 'devise_token_auth_create_#{user_class.pluralize.gsub('::','').underscore}' already exists")
      else
        migration_template(
          'devise_token_auth_create_users.rb.erb',
          "db/migrate/devise_token_auth_create_#{user_class.pluralize.gsub('::','').underscore}.rb"
        )
      end
    end

    def create_user_model
      fname = "app/models/#{user_class.underscore}.rb"
      if File.exist?(File.join(destination_root, fname))
        inclusion = 'include DeviseTokenAuth::Concerns::User'
        unless parse_file_for_line(fname, inclusion)

          active_record_needle = (Rails::VERSION::MAJOR >= 5) ? 'ApplicationRecord' : 'ActiveRecord::Base'
          inject_into_file fname, after: "class #{user_class} < #{active_record_needle}\n" do <<-'RUBY'
            # Include default devise modules.
            devise :database_authenticatable, :registerable,
                    :recoverable, :rememberable, :trackable, :validatable,
                    :confirmable, :omniauthable
            include DeviseTokenAuth::Concerns::User
            RUBY
          end
        end
      else
        template('user.rb.erb', fname)
      end
    end

    private

    def self.next_migration_number(path)
      Time.zone.now.utc.strftime('%Y%m%d%H%M%S')
    end

    def json_supported_database?
      (postgres? && postgres_correct_version?) || (mysql? && mysql_correct_version?)
    end

    def postgres?
      database_name == 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    end

    def postgres_correct_version?
      database_version > '9.3'
    end

    def mysql?
      database_name == 'ActiveRecord::ConnectionAdapters::MysqlAdapter'
    end

    def mysql_correct_version?
      database_version > '5.7.7'
    end

    def database_name
      ActiveRecord::Base.connection.class.name
    end

    def database_version
      ActiveRecord::Base.connection.select_value('SELECT VERSION()')
    end

    def rails_5_or_newer?
      Rails::VERSION::MAJOR >= 5
    end

    def primary_key_type
      primary_key_string if rails_5_or_newer?
    end

    def primary_key_string
      key_string = options[:primary_key_type]
      ", id: :#{key_string}" if key_string
    end
  end
end
