# == Schema Information
#
# Table name: account_addresses
#
#  id                     :bigint           not null, primary key
#  street                 :string           not null
#  exterior_number        :string           not null
#  interior_number        :string
#  neighborhood           :string           not null
#  postal_code            :string           not null
#  city                   :string           not null
#  state                  :string           not null
#  email                  :string
#  phone                  :string
#  webpage                :string
#  establishment_summary  :text
#  account_id             :bigint           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_account_addresses_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class AccountAddress < ApplicationRecord
  belongs_to :account

  validates :street, :exterior_number, :neighborhood, :postal_code, :city, :state, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[\d\s\-+()]+\z/ }, allow_blank: true
  validates :webpage, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
end
