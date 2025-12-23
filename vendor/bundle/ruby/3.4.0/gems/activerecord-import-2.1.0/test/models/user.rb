# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :user_tokens, primary_key: :name, foreign_key: :user_name
end
