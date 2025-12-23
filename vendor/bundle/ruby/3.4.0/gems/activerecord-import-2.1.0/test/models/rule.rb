# frozen_string_literal: true

class Rule < ActiveRecord::Base
  belongs_to :question
end
