class Company < ApplicationRecord
  belongs_to :account
  has_many :contacts, dependent: :nullify

  validates :name, presence: true
end
