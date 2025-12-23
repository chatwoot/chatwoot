# frozen_string_literal: true

class Question < ActiveRecord::Base
  has_one :rule
end
