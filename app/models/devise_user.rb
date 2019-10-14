# frozen_string_literal: true

class DeviseUser < ActiveRecord::Base
  include DeviseTokenAuth::Concerns::User

  devise :confirmable,
    :database_authenticatable, 
    :recoverable, 
    :registerable,
    :rememberable, 
    :trackable, 
    :validatable

  validates :email, presence: true
  validates :name, presence: true
end
