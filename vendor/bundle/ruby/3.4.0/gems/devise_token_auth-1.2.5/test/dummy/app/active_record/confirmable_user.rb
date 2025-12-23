# frozen_string_literal: true

class ConfirmableUser < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :validatable, :confirmable
  DeviseTokenAuth.send_confirmation_email = true
  include DeviseTokenAuth::Concerns::User
  DeviseTokenAuth.send_confirmation_email = false
end
