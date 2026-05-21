FactoryBot.define do
  factory :reporting_events_rollup do
    account
    date { Date.current }
    dimension_type { 'account' }
    dimension_id { 1 }
    metric { 'first_response' }
    count { 1 }
    sum_value { 100.0 }
    sum_value_business_hours { 50.0 }
  end
end
