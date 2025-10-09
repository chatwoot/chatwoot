# frozen_string_literal: true

FactoryBot.define do
  factory :custom_attribute_definition do
    sequence(:attribute_display_name) { |n| "Custom Attribute Definition #{n}" }
    sequence(:attribute_key) { |n| "custom_attribute_#{n}" }
    attribute_display_type { 1 }
    attribute_model { 0 }
    default_value { nil }
    account

    trait :with_datetime_type do
      attribute_display_type { 8 }
      attribute_display_name { 'Event Date Time' }
      attribute_key { 'event_datetime' }
    end

    trait :with_date_type do
      attribute_display_type { 5 }
      attribute_display_name { 'Event Date' }
      attribute_key { 'event_date' }
    end

    trait :with_list_type do
      attribute_display_type { 6 }
      attribute_display_name { 'Priority' }
      attribute_key { 'priority' }
      attribute_values { %w[low medium high] }
    end

    trait :with_checkbox_type do
      attribute_display_type { 7 }
      attribute_display_name { 'Is Active' }
      attribute_key { 'is_active' }
    end
  end
end
