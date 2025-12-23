# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'generators/devise_token_auth/install_generator' if DEVISE_TOKEN_AUTH_ORM == :active_record
require 'generators/devise_token_auth/install_mongoid_generator' if DEVISE_TOKEN_AUTH_ORM == :mongoid

module DeviseTokenAuth
  class InstallGeneratorTest < Rails::Generators::TestCase
    tests InstallGenerator        if DEVISE_TOKEN_AUTH_ORM == :active_record
    tests InstallMongoidGenerator if DEVISE_TOKEN_AUTH_ORM == :mongoid
    destination Rails.root.join('tmp/generators')

    # The namespaced user model for testing
    let(:user_class) { 'Azpire::V1::HumanResource::User' }
    let(:namespace_path) { user_class.underscore }
    let(:table_name) { user_class.pluralize.underscore.gsub('/','_') }

    describe 'user model with namespace, clean install' do
      setup :prepare_destination

      before do
        run_generator %W[#{user_class} auth]
      end

      test 'user model (with namespace) is created, concern is included' do
        assert_file "app/models/#{namespace_path}.rb" do |model|
          assert_match(/include DeviseTokenAuth::Concerns::User/, model)
        end
      end

      test 'initializer is created' do
        assert_file 'config/initializers/devise_token_auth.rb'
      end

      test 'subsequent runs raise no errors' do
        run_generator %W[#{user_class} auth]
      end

      if DEVISE_TOKEN_AUTH_ORM == :active_record
        test 'migration is created for user model with namespace' do
          assert_migration "db/migrate/devise_token_auth_create_#{table_name}.rb"
        end

        test 'migration file for user model with namespace contains rails version' do
          if Rails::VERSION::MAJOR >= 5
            assert_migration "db/migrate/devise_token_auth_create_#{table_name}.rb", /#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}/
          else
            assert_migration "db/migrate/devise_token_auth_create_#{table_name}.rb"
          end
        end

        test 'add primary key type with rails 5 when specified in rails generator' do
          run_generator %W[#{user_class} auth --primary_key_type=uuid --force]
          if Rails::VERSION::MAJOR >= 5
            assert_migration "db/migrate/devise_token_auth_create_#{table_name}.rb", /create_table\(:#{table_name}, id: :uuid\) do/
          else
            assert_migration "db/migrate/devise_token_auth_create_#{table_name}.rb", /create_table\(:#{table_name}\) do/
          end
        end
      end
    end

    describe 'existing user model' do
      setup :prepare_destination

      before do
        @dir = File.join(destination_root, 'app', 'models')

        @fname = File.join(@dir, 'user.rb')

        # make dir if not exists
        FileUtils.mkdir_p(@dir)

        case DEVISE_TOKEN_AUTH_ORM
        when :active_record
          # account for rails version 5
          active_record_needle = (Rails::VERSION::MAJOR >= 5) ? 'ApplicationRecord' : 'ActiveRecord::Base'

          @f = File.open(@fname, 'w') do |f|
            f.write <<-RUBY
              class User < #{active_record_needle}

                def whatever
                  puts 'whatever'
                end
              end
            RUBY
          end
        when :mongoid
          @f = File.open(@fname, 'w') do |f|
            f.write <<-'RUBY'
              class User

                def whatever
                  puts 'whatever'
                end
              end
            RUBY
          end
        end

        run_generator
      end

      test 'user concern is injected into existing model' do
        assert_file 'app/models/user.rb' do |model|
          assert_match(/include DeviseTokenAuth::Concerns::User/, model)
        end
      end

      test 'subsequent runs do not modify file' do
        run_generator
        assert_file 'app/models/user.rb' do |model|
          matches = model.scan(/include DeviseTokenAuth::Concerns::User/m).size
          assert_equal 1, matches
        end
      end
    end

    describe 'routes' do
      setup :prepare_destination

      before do
        @dir = File.join(destination_root, 'config')

        @fname = File.join(@dir, 'routes.rb')

        # make dir if not exists
        FileUtils.mkdir_p(@dir)

        @f = File.open(@fname, 'w') do |f|
          f.write <<-RUBY
            Rails.application.routes.draw do
              patch '/chong', to: 'bong#index'
            end
          RUBY
        end

        run_generator %W[#{user_class} auth]
      end

      test 'route method for user model with namespace is appended to routes file' do
        assert_file 'config/routes.rb' do |routes|
          assert_match(/mount_devise_token_auth_for '#{user_class}', at: 'auth'/, routes)
        end
      end

      test 'subsequent runs do not modify file' do
        run_generator %W[#{user_class} auth]
        assert_file 'config/routes.rb' do |routes|
          matches = routes.scan(/mount_devise_token_auth_for '#{user_class}', at: 'auth'/m).size
          assert_equal 1, matches
        end
      end

      describe 'subsequent models' do
        before do
          run_generator %w[Mang mangs]
        end

        test 'route method is appended to routes file' do
          assert_file 'config/routes.rb' do |routes|
            assert_match(/mount_devise_token_auth_for 'Mang', at: 'mangs'/, routes)
          end
        end

        test 'devise_for block is appended to routes file' do
          assert_file 'config/routes.rb' do |routes|
            assert_match(/as :mang do/, routes)
            assert_match(/# Define routes for Mang within this block./, routes)
          end
        end

        if DEVISE_TOKEN_AUTH_ORM == :active_record
          test 'migration is created' do
            assert_migration 'db/migrate/devise_token_auth_create_mangs.rb'
          end
        end
      end
    end

    describe 'application controller' do
      setup :prepare_destination

      before do
        @dir = File.join(destination_root, 'app', 'controllers')

        @fname = File.join(@dir, 'application_controller.rb')

        # make dir if not exists
        FileUtils.mkdir_p(@dir)

        @f = File.open(@fname, 'w') do |f|
          f.write <<-RUBY
            class ApplicationController < ActionController::Base
              def whatever
                'whatever'
              end
            end
          RUBY
        end

        run_generator %W[#{user_class} auth]
      end

      test 'controller concern is appended to application controller' do
        assert_file 'app/controllers/application_controller.rb' do |controller|
          assert_match(/include DeviseTokenAuth::Concerns::SetUserByToken/, controller)
        end
      end

      test 'subsequent runs do not modify file' do
        run_generator %W[#{user_class} auth]
        assert_file 'app/controllers/application_controller.rb' do |controller|
          matches = controller.scan(/include DeviseTokenAuth::Concerns::SetUserByToken/m).size
          assert_equal 1, matches
        end
      end
    end
  end
end
