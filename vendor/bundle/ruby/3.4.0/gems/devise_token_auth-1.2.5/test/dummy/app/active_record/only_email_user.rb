# frozen_string_literal: true

class OnlyEmailUser < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable
  include DeviseTokenAuth::Concerns::User
end
