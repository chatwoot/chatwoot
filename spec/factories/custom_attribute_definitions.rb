# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_attribute_definitions
#
#  id                     :bigint           not null, primary key
#  attribute_description  :text
#  attribute_display_name :string
#  attribute_display_type :integer          default("text")
#  attribute_key          :string
#  attribute_model        :integer          default("conversation_attribute")
#  attribute_values       :jsonb
#  default_value          :integer
#  regex_cue              :string
#  regex_pattern          :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  attribute_key_model_index                         (attribute_key,attribute_model,account_id) UNIQUE
#  index_custom_attribute_definitions_on_account_id  (account_id)
#
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
