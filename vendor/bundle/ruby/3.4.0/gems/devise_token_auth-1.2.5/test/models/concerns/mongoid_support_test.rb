# frozen_string_literal: true

require 'test_helper'

if DEVISE_TOKEN_AUTH_ORM == :mongoid
  class DeviseTokenAuth::Concerns::MongoidSupportTest < ActiveSupport::TestCase
    describe DeviseTokenAuth::Concerns::MongoidSupport do
      before do
        @user = create(:user)
      end

      describe '#as_json' do
        test 'should be defined' do
          assert @user.methods.include?(:as_json)
        end

        test 'should except _id attribute' do
          refute @user.as_json.key?('_id')
        end

        test 'should return with id attribute' do
          assert_equal @user._id.to_s, @user.as_json['id']
        end

        test 'should accept options' do
          refute @user.as_json(except: [:created_at]).key?('created_at')
        end
      end
    end
  end
end
