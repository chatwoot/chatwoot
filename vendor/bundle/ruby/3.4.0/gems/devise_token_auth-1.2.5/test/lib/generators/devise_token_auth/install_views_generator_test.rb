# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'generators/devise_token_auth/install_views_generator'

module DeviseTokenAuth
  class InstallViewsGeneratorTest < Rails::Generators::TestCase
    tests InstallViewsGenerator
    destination Rails.root.join('tmp/generators')

    describe 'default values, clean install' do
      setup :prepare_destination

      before do
        run_generator
      end

      test 'files are copied' do
        assert_file 'app/views/devise/mailer/reset_password_instructions.html.erb'
        assert_file 'app/views/devise/mailer/confirmation_instructions.html.erb'
      end
    end
  end
end
