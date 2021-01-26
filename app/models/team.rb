# == Schema Information
#
# Table name: teams
#
#  id                :bigint           not null, primary key
#  allow_auto_assign :boolean          default(TRUE)
#  description       :text
#  name              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#
# Indexes
#
#  index_teams_on_account_id           (account_id)
#  index_teams_on_name_and_account_id  (name,account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Team < ApplicationRecord
  include RegexHelper

  belongs_to :account
  has_many :team_members, dependent: :destroy
  has_many :conversations, dependent: :nullify

  validates :name,
            presence: { message: 'must not be blank' },
            format: { with: UNICODE_CHARACTER_NUMBER_HYPHEN_UNDERSCORE },
            uniqueness: { scope: :account_id }

  before_validation do
    self.name = name.downcase if attribute_present?('name')
  end
end
