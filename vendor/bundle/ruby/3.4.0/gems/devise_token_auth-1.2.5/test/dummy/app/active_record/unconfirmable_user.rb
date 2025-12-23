# frozen_string_literal: true

class UnconfirmableUser < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :validatable, :omniauthable
  include DeviseTokenAuth::Concerns::User
end
