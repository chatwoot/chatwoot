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

  before_validation :set_uid_to_email, on: :create

  # renamed; this only sets the uid currently
  def set_uid_to_email
    self.uid = self.email
  end
end
