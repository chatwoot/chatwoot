# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DemoGroupControllerTest < ActionDispatch::IntegrationTest
  describe DemoGroupController do
    describe 'Token access' do
      before do
        # user
        @resource = create(:user, :confirmed)

        @resource_auth_headers = @resource.create_new_auth_token

        @resource_token     = @resource_auth_headers['access-token']
        @resource_client_id = @resource_auth_headers['client']
        @resource_expiry    = @resource_auth_headers['expiry']

        # mang
        @mang = create(:mang_user, :confirmed)

        @mang_auth_headers = @mang.create_new_auth_token

        @mang_token     = @mang_auth_headers['access-token']
        @mang_client_id = @mang_auth_headers['client']
        @mang_expiry    = @mang_auth_headers['expiry']
      end

      describe 'user access' do
        before do
          # ensure that request is not treated as batch request
          age_token(@resource, @resource_client_id)

          get '/demo/members_only_group',
              params: {},
              headers: @resource_auth_headers

          @resp_token       = response.headers['access-token']
          @resp_client_id   = response.headers['client']
          @resp_expiry      = response.headers['expiry']
          @resp_uid         = response.headers['uid']
        end

        test 'request is successful' do
          assert_equal 200, response.status
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end

          it 'should define current_member' do
            assert_equal @resource, @controller.current_member
          end

          it 'should define current_members' do
            assert @controller.current_members.include? @resource
          end

          it 'should define member_signed_in?' do
            assert @controller.current_members.include? @resource
          end

          it 'should define render_authenticate_error' do
            assert @controller.methods.include?(:render_authenticate_error)
          end
        end
      end

      describe 'mang access' do
        before do
          # ensure that request is not treated as batch request
          age_token(@mang, @mang_client_id)

          get '/demo/members_only_group',
              params: {},
              headers: @mang_auth_headers

          @resp_token       = response.headers['access-token']
          @resp_client_id   = response.headers['client']
          @resp_expiry      = response.headers['expiry']
          @resp_uid         = response.headers['uid']
        end

        test 'request is successful' do
          assert_equal 200, response.status
        end

        describe 'devise mappings' do
          it 'should define current_mang' do
            assert_equal @mang, @controller.current_mang
          end

          it 'should define mang_signed_in?' do
            assert @controller.mang_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @mang, @controller.current_user
          end

          it 'should define current_member' do
            assert_equal @mang, @controller.current_member
          end

          it 'should define current_members' do
            assert @controller.current_members.include? @mang
          end

          it 'should define member_signed_in?' do
            assert @controller.current_members.include? @mang
          end

          it 'should define render_authenticate_error' do
            assert @controller.methods.include?(:render_authenticate_error)
          end
        end
      end

      describe 'failed access' do
        before do
          get '/demo/members_only_group',
              params: {},
              headers: @mang_auth_headers.merge('access-token' => 'bogus')
        end

        it 'should not return any auth headers' do
          refute response.headers['access-token']
        end

        it 'should return error: unauthorized status' do
          assert_equal 401, response.status
        end
      end
    end
  end
end
