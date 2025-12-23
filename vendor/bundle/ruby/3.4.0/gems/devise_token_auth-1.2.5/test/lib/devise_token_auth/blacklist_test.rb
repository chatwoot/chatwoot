# frozen_string_literal: true

require 'test_helper'

class DeviseTokenAuth::BlacklistTest < ActiveSupport::TestCase
  if defined? Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION
    describe Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION do
      test 'should include :tokens' do
        assert Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION.include?(:tokens)
      end
    end
  else
    describe Devise::Models::Authenticatable::BLACKLIST_FOR_SERIALIZATION do
      test 'should include :tokens' do
        assert Devise::Models::Authenticatable::BLACKLIST_FOR_SERIALIZATION.include?(:tokens)
      end
    end
  end
end
