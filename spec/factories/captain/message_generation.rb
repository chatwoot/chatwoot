FactoryBot.define do
  factory :captain_message_generation, class: 'Captain::MessageGeneration' do
    reasoning { 'Matched the FAQ about creating an account.' }
    model { 'gpt-4o-mini' }
    citations { [{ 'title' => 'How to create an account?', 'source' => 'https://example.com/docs', 'document_id' => nil }] }
    generation_path { [{ 'tool' => 'search_documentation', 'arguments' => { 'query' => 'account' }, 'result' => 'Question: ...' }] }
    association :message
    association :assistant, factory: :captain_assistant
  end
end
