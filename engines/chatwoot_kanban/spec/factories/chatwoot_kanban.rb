FactoryBot.define do
  factory :kanban_board, class: 'ChatwootKanban::Board' do
    association :account
    sequence(:name) { |n| "Board ##{n}" }
    description     { 'spec board' }
  end

  factory :kanban_column, class: 'ChatwootKanban::Column' do
    association :board, factory: :kanban_board
    sequence(:name)     { |n| "Column ##{n}" }
    sequence(:position) { |n| n }
  end

  factory :kanban_card, class: 'ChatwootKanban::Card' do
    association :column, factory: :kanban_column
    sequence(:title)    { |n| "Card ##{n}" }
    sequence(:position) { |n| n }
    priority            { :medium }
  end

  factory :kanban_label, class: 'ChatwootKanban::Label' do
    association :account
    sequence(:name) { |n| "Label ##{n}" }
    color           { '#ff0000' }
  end

  factory :kanban_comment, class: 'ChatwootKanban::Comment' do
    association :card,   factory: :kanban_card
    association :author, factory: :user
    content { 'Test comment' }
  end

  factory :kanban_checklist_item, class: 'ChatwootKanban::ChecklistItem' do
    association :card, factory: :kanban_card
    sequence(:title)    { |n| "Item ##{n}" }
    sequence(:position) { |n| n }
    completed           { false }
  end
end
