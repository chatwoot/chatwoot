FactoryBot.define do
  factory :ctwa_tracked_link_click, class: 'Ctwa::TrackedLinkClick' do
    account
    tracked_link { association(:ctwa_tracked_link, account: account) }
    params { { 'gclid' => 'test-gclid', 'utm_campaign' => 'july' } }
    user_agent { 'RSpec' }
  end
end
