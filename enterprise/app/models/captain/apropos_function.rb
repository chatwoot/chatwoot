# == Schema Information
#
# Table name: captain_apropos_functions
#
#  id          :bigint           not null, primary key
#  definition  :jsonb            not null
#  description :string           not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  idx_on_account_id_user_id_name_d199cd70e7  (account_id,user_id,name) UNIQUE
#
class Captain::AproposFunction < ApplicationRecord
  self.table_name = 'captain_apropos_functions'

  belongs_to :account
  belongs_to :user

  validates :name, :description, :definition, presence: true
  validates :name, uniqueness: { scope: [:account_id, :user_id] }
end
