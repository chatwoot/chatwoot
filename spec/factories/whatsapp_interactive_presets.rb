FactoryBot.define do
  factory :whatsapp_interactive_preset do
    account
    created_by { association(:user, account: account) }
    sequence(:name) { |number| "Interactive preset #{number}" }
    definition do
      {
        'schema_version' => 1,
        'type' => 'button',
        'body' => { 'text' => 'Choose an option' },
        'action' => { 'buttons' => [{ 'title' => 'Continue' }] }
      }
    end
  end
end
