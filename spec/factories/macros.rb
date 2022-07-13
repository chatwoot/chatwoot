FactoryBot.define do
  factory :macro do
    account
    name { 'wrong_message_actions' }
    actions do
      [
        { 'action_name' => 'add_label', 'action_params' => %w[wrong_chat] }
      ]
    end
  end
end
