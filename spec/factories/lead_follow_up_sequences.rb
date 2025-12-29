# frozen_string_literal: true

FactoryBot.define do
  factory :lead_follow_up_sequence do
    sequence(:name) { |n| "Lead Follow-up Sequence #{n}" }
    sequence(:description) { |n| "Description for sequence #{n}" }
    active { true }
    steps do
      [
        {
          'id' => 'wait_1',
          'type' => 'wait',
          'enabled' => true,
          'config' => {
            'delay_value' => 2,
            'delay_type' => 'hours'
          }
        },
        {
          'id' => 'template_1',
          'type' => 'send_template',
          'enabled' => true,
          'config' => {
            'template_name' => 'follow_up_message',
            'language' => 'en',
            'template_params' => {
              'body' => {
                '1' => '{{contact.name}}'
              }
            }
          }
        }
      ]
    end
    settings do
      {
        'stop_on_contact_reply' => true,
        'stop_on_conversation_resolved' => true,
        'respect_business_hours' => false,
        'business_hours' => {
          'start' => '09:00',
          'end' => '18:00',
          'timezone' => 'UTC'
        },
        'max_retries_per_step' => 2
      }
    end
    stats { {} }

    after(:build) do |sequence|
      sequence.account ||= create(:account)
      sequence.inbox ||= create(
        :inbox,
        account: sequence.account,
        channel: create(:channel_whatsapp, account: sequence.account)
      )
    end
  end
end
