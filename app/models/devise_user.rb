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

  validates_uniqueness_of :email, scope: :account
  validates :email, presence: true
  validates :name, presence: true

  has_one :user, dependent: :destroy
  has_one :inviter, through: :user
  has_one :account, through: :user
  delegate :role, to: :user

  accepts_nested_attributes_for :user

  before_validation :set_uid_to_email, on: :create

  # renamed; this only sets the uid currently
  def set_uid_to_email
    self.uid = self.email
  end

  def user
    super || build_user
  end
end
