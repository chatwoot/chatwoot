require 'rails_helper'
require Rails.root.join('rubocop/feature_access_role_check').to_s
require 'rubocop/rspec/support'

RSpec.describe RuboCop::Cop::Chatwoot::FeatureAccessRoleCheck, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'flags an agent decided by role' do
    expect_offense(<<~RUBY)
      def index?
        @account_user&.agent?
        ^^^^^^^^^^^^^^^^^^^^^ Decide what an agent may use with `FeatureAccess`, not with the member role.
      end
    RUBY
  end

  it 'flags a comparison of the member role' do
    expect_offense(<<~RUBY)
      account_user.role == 'agent'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Decide what an agent may use with `FeatureAccess`, not with the member role.
    RUBY
  end

  it 'leaves administrator-only operations alone' do
    expect_no_offenses(<<~RUBY)
      def destroy?
        @account_user&.administrator?
      end
    RUBY
  end

  it 'is enabled only for the authorization code of gated features' do
    config = RuboCop::ConfigLoader.load_file(Rails.root.join('.rubocop.yml').to_s)
    included = ->(path) { config.for_cop('Chatwoot/FeatureAccessRoleCheck')['Include'].any? { |glob| File.fnmatch?(glob, path, File::FNM_PATHNAME) } }

    expect(included.call('app/policies/internal_chat/channel_policy.rb')).to be(true)
    expect(included.call('app/controllers/api/v1/accounts/internal_chat/drafts_controller.rb')).to be(true)
    expect(included.call('app/policies/conversation_policy.rb')).to be(false)
  end
end
