# frozen_string_literal: true

FactoryBot.define do
  factory :message_template do
    association :account
    association :inbox
    sequence(:name) { |n| "template_#{n}" }
    category { 'marketing' }
    status { 'draft' }
    language { 'en' }
    channel_type { 'Channel::Whatsapp' }
    content { { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello, this is a test message' }] } }
    metadata { {} }
    platform_template_id { 'test_template_id' } # Set this to skip the before_create callback
    parameter_format { 'positional' }
  end
end
