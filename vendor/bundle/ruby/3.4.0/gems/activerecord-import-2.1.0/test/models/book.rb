# frozen_string_literal: true

class Book < ActiveRecord::Base
  belongs_to :topic, inverse_of: :books
  if ENV['AR_VERSION'].to_f <= 7.0 || ENV['AR_VERSION'].to_f >= 8.0
    belongs_to :tag, foreign_key: [:tag_id, :parent_id] unless ENV["SKIP_COMPOSITE_PK"]
  else
    belongs_to :tag, query_constraints: [:tag_id, :parent_id] unless ENV["SKIP_COMPOSITE_PK"]
  end
  has_many :chapters, inverse_of: :book
  has_many :discounts, as: :discountable
  has_many :end_notes, inverse_of: :book
  if ENV['AR_VERSION'].to_f >= 8.0
    enum :status, [:draft, :published]
  else
    enum status: [:draft, :published]
  end
end
