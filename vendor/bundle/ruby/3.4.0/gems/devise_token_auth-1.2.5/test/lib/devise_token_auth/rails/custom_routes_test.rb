# frozen_string_literal: true

require 'test_helper'

class DeviseTokenAuth::CustomRoutesTest < ActiveSupport::TestCase
  after do
    Rails.application.reload_routes!
  end
  test 'custom controllers' do
    class ActionDispatch::Routing::Mapper
        include Mocha::ParameterMatchers
    end
    Rails.application.routes.draw do
      self.expects(:devise_for).with(
        :users,
        has_entries(
          controllers: has_entries(
            invitations: "custom/invitations", foo: "custom/foo"
          )
        )
      )

      mount_devise_token_auth_for 'User', at: 'my_custom_users', controllers: {
        invitations: 'custom/invitations',
        foo: 'custom/foo'
      }
    end
  end
end
