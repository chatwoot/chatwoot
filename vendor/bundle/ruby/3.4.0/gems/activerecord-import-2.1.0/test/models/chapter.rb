# frozen_string_literal: true

class Chapter < ActiveRecord::Base
  belongs_to :book, inverse_of: :chapters
  validates :title, presence: true
end
