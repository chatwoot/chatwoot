# frozen_string_literal: true

class UserToken < ActiveRecord::Base
  belongs_to :user, primary_key: :name, foreign_key: :user_name
  validates :user, presence: true
end
