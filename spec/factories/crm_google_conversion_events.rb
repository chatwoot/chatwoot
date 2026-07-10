FactoryBot.define do
  factory :crm_google_conversion_event, class: 'Crm::GoogleConversionEvent' do
    account
    sequence(:card_id)
    sequence(:activity_id)
    sequence(:event_id) { |n| "crm-#{card_id}-won-#{n}" }
    gclid { 'test-gclid' }
    conversion_name { 'Venda WhatsApp' }
    conversion_time { Time.current }
    status { 'ready' }
  end
end
