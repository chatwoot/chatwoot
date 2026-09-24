require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Session Store Configuration' do
  # rubocop:enable RSpec/DescribeClass

  let(:session_options) { Rails.application.config.session_options }

  it 'uses cookie_store as the session store' do
    expect(Rails.application.config.session_store).to eq(ActionDispatch::Session::CookieStore)
  end

  it 'sets the session key' do
    expect(session_options[:key]).to eq('_chatwoot_session')
  end

  it 'sets same_site to lax' do
    expect(session_options[:same_site]).to eq(:lax)
  end

  it 'sets httponly to true' do
    expect(session_options[:httponly]).to be(true)
  end

  it 'sets secure flag based on FORCE_SSL' do
    expected_secure = ActiveModel::Type::Boolean.new.cast(ENV.fetch('FORCE_SSL', false))
    expect(session_options[:secure]).to eq(expected_secure)
  end
end
