# rubocop:disable Layout/LineLength

# == Schema Information
#
# Table name: companies
#
#  id                  :bigint           not null, primary key
#  custom_attributes   :jsonb            not null
#  description         :text
#  email               :string
#  name                :string           not null
#  phone               :string
#  website             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :integer          not null
#
# Indexes
#
#  index_companies_on_account_id            (account_id)
#  index_companies_on_account_id_and_name   (account_id,name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class Company < ApplicationRecord
  belongs_to :account
  has_many :contacts, dependent: :nullify

  validates :name, presence: true
end
