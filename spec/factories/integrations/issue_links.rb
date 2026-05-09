FactoryBot.define do
  factory :integrations_issue_link, class: 'Integrations::IssueLink' do
    association :conversation
    account { conversation.account }
    app_id { 'notion' }
    sequence(:external_id) { |n| "issue-#{n}" }
    external_url { "https://www.notion.so/#{external_id}" }
    external_title { 'Customer issue' }
    metadata { {} }
  end
end
