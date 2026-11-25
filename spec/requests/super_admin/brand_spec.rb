require 'rails_helper'

RSpec.describe 'Super Admin sidebar version' do
  let(:super_admin) { create(:super_admin) }

  before do
    allow(Chatwoot).to receive(:config).and_return(Chatwoot.config.merge(version: '4.20.1'))
    sign_in(super_admin, scope: :super_admin)
  end

  it 'shows the version without linking to upstream release notes or hinting at an update' do
    Redis::Alfred.set(Redis::Alfred::LATEST_CHATWOOT_VERSION, '9.9.9')

    get '/super_admin'

    expect(response.body).to include('v4.20.1')
    expect(response.body).not_to include('fazer.ai')
    expect(response.body).not_to include('github.com/chatwoot/chatwoot/releases')
    expect(response.body).not_to include('bg-n-amber-9')
  ensure
    Redis::Alfred.delete(Redis::Alfred::LATEST_CHATWOOT_VERSION)
  end
end
