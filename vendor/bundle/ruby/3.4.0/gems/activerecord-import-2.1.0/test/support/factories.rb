# frozen_string_literal: true

FactoryBot.define do
  sequence(:book_title) { |n| "Book #{n}" }
  sequence(:chapter_title) { |n| "Chapter #{n}" }
  sequence(:end_note) { |n| "Endnote #{n}" }

  factory :group do
    sequence(:order) { |n| "Order #{n}" }
  end

  factory :invalid_topic, class: "Topic" do
    sequence(:title) { |n| "Title #{n}" }
    author_name { nil }
  end

  factory :topic do
    sequence(:title) { |n| "Title #{n}" }
    sequence(:author_name) { |n| "Author #{n}" }
    sequence(:content) { |n| "Content #{n}" }
  end

  factory :widget do
    sequence(:w_id) { |n| n }
  end

  factory :question do
    sequence(:body) { |n| "Text #{n}" }

    trait :with_rule do
      after(:build) do |question|
        question.build_rule(FactoryBot.attributes_for(:rule))
      end
    end
  end

  factory :rule do
    sequence(:id) { |n| n }
    sequence(:condition_text) { |n| "q_#{n}_#{n}" }
  end

  factory :topic_with_book, parent: :topic do
    after(:build) do |topic|
      2.times do
        book = topic.books.build(title: FactoryBot.generate(:book_title), author_name: 'Stephen King')
        3.times do
          book.chapters.build(title: FactoryBot.generate(:chapter_title))
        end

        4.times do
          book.end_notes.build(note: FactoryBot.generate(:end_note))
        end
      end
    end
  end

  factory :book do
    title { 'Tortilla Flat' }
    author_name { 'John Steinbeck' }
  end

  factory :car do
    sequence(:Name) { |n| n }
    sequence(:Features) { |n| "Feature #{n}" }
  end
end
