# frozen_string_literal: true

FactoryBot.define do
  factory :custom_attribute_definition do
    sequence(:attribute_display_name) { |n| "Custom Attribute Definition #{n}" }
    sequence(:attribute_key) { |n| "custom_attribute_#{n}" }
    attribute_display_type { 1 }
    attribute_model { 0 }
    default_value { nil }
    account
  end
end
