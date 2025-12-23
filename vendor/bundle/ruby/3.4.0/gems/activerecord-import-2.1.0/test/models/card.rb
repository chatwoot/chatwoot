# frozen_string_literal: true

class Card < ActiveRecord::Base
  belongs_to :deck, polymorphic: true
end
