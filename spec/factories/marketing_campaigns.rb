# spec/factories/marketing_campaigns.rb
FactoryBot.define do
  factory :marketing_campaign do
    association :account
    title { 'Campaña de prueba' }
    description { 'Descripción' }
    start_date { Time.zone.today }
    end_date { Time.zone.today + 7.days }
    active { true }
    source_id { 'META-001' }
  end
end
