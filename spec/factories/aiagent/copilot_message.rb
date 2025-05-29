FactoryBot.define do
  factory :aiagent_copilot_message, class: 'CopilotMessage' do
    account
    user
    copilot_thread { association :aiagent_copilot_thread }
    message { { content: 'This is a test message' } }
    message_type { 'user' }
  end
end
