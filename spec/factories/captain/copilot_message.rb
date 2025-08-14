FactoryBot.define do
  factory :captain_copilot_message, class: 'CopilotMessage' do
    account
    copilot_thread { association :captain_copilot_thread }
    message { { content: 'This is a test message' } }
    message_type { 0 }
  end
end
