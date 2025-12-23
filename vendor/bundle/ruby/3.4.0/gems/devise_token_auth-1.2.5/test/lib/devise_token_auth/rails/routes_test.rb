# frozen_string_literal: true

require 'test_helper'

# Needed for MiniTest to start a controller test so we can use assert_recognizes
class DeviseTokenAuth::RoutesTestController < DeviseTokenAuth::ApplicationController
end

class DeviseTokenAuth::RoutesTest < ActionController::TestCase
  self.controller_class = DeviseTokenAuth::RoutesTestController
  before do
    Rails.application.routes.draw do
      mount_devise_token_auth_for 'User', at: 'my_custom_users', controllers: {
        invitations: 'custom/invitations',
        foo: 'custom/foo'
      }
    end
  end

  after do
    Rails.application.reload_routes!
  end

  test 'map new user session' do
    assert_recognizes({controller: 'devise_token_auth/sessions', action: 'new'}, {path: 'my_custom_users/sign_in', method: :get})
  end

  test 'map create user session' do
    assert_recognizes({controller: 'devise_token_auth/sessions', action: 'create'}, {path: 'my_custom_users/sign_in', method: :post})
  end

  test 'map destroy user session' do
    assert_recognizes({controller: 'devise_token_auth/sessions', action: 'destroy'}, {path: 'my_custom_users/sign_out', method: :delete})
  end

  test 'map new user confirmation' do
    assert_recognizes({controller: 'devise_token_auth/confirmations', action: 'new'}, 'my_custom_users/confirmation/new')
  end

  test 'map create user confirmation' do
    assert_recognizes({controller: 'devise_token_auth/confirmations', action: 'create'}, {path: 'my_custom_users/confirmation', method: :post})
  end

  test 'map show user confirmation' do
    assert_recognizes({controller: 'devise_token_auth/confirmations', action: 'show'}, {path: 'my_custom_users/confirmation', method: :get})
  end

  test 'map new user password' do
    assert_recognizes({controller: 'devise_token_auth/passwords', action: 'new'}, 'my_custom_users/password/new')
  end

  test 'map create user password' do
    assert_recognizes({controller: 'devise_token_auth/passwords', action: 'create'}, {path: 'my_custom_users/password', method: :post})
  end

  test 'map edit user password' do
    assert_recognizes({controller: 'devise_token_auth/passwords', action: 'edit'}, 'my_custom_users/password/edit')
  end

  test 'map update user password' do
    assert_recognizes({controller: 'devise_token_auth/passwords', action: 'update'}, {path: 'my_custom_users/password', method: :put})
  end

  test 'map new user registration' do
    assert_recognizes({controller: 'devise_token_auth/registrations', action: 'new'}, 'my_custom_users/sign_up')
  end

  test 'map create user registration' do
    assert_recognizes({controller: 'devise_token_auth/registrations', action: 'create'}, {path: 'my_custom_users', method: :post})
  end

  test 'map edit user registration' do
    assert_recognizes({controller: 'devise_token_auth/registrations', action: 'edit'}, {path: 'my_custom_users/edit', method: :get})
  end

  test 'map update user registration' do
    assert_recognizes({controller: 'devise_token_auth/registrations', action: 'update'}, {path: 'my_custom_users', method: :put})
  end

  test 'map destroy user registration' do
    assert_recognizes({controller: 'devise_token_auth/registrations', action: 'destroy'}, {path: 'my_custom_users', method: :delete})
  end

  test 'map cancel user registration' do
    assert_recognizes({controller: 'devise_token_auth/registrations', action: 'cancel'}, {path: 'my_custom_users/cancel', method: :get})
  end
end