# frozen_string_literal: true

class CompositeChapter < ActiveRecord::Base
  if ENV['AR_VERSION'].to_f >= 8.0
    belongs_to :composite_book, inverse_of: :composite_chapters,
                                foreign_key: [:composite_book_id, :author_id]
  elsif ENV['AR_VERSION'].to_f >= 7.1
    belongs_to :composite_book, inverse_of: :composite_chapters,
                                query_constraints: [:composite_book_id, :author_id]
  end
  validates :title, presence: true
end
