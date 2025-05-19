FactoryBot.define do
  factory :captain_copilot_message, class: 'CopilotMessage' do
    account
    user
    copilot_thread { association :captain_copilot_thread }
    message { { content: 'This is a test message' } }
    message_type { 'user' }
  end
end
