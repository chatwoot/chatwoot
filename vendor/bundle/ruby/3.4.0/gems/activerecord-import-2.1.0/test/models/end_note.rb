# frozen_string_literal: true

class EndNote < ActiveRecord::Base
  belongs_to :book, inverse_of: :end_notes
  validates :note, presence: true
end
