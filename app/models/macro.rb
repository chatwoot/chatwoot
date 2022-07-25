# == Schema Information
#
# Table name: macros
#
#  id            :bigint           not null, primary key
#  actions       :jsonb            not null
#  name          :string           not null
#  visibility    :integer          default("user")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  created_by_id :bigint           not null
#  updated_by_id :bigint           not null
#
# Indexes
#
#  index_macros_on_account_id     (account_id)
#  index_macros_on_created_by_id  (created_by_id)
#  index_macros_on_updated_by_id  (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class Macro < ApplicationRecord
  belongs_to :account
  belongs_to :created_by,
             class_name: :User
  belongs_to :updated_by,
             class_name: :User
  enum visibility: { personal: 0, global: 1 }

  def set_visibility(user, params)
    self.visibility = params[:visibility]
    self.visibility = :personal if user.agent?
  end

  def self.with_visibility(user, params)
    records = user.administrator? ? Current.account.macros : Current.account.macros.global
    records = records.or(personal.where(created_by_id: user.id)) if user.agent?
    records.page(current_page(params))
    records
  end

  def self.current_page(params)
    params[:page] || 1
  end
end
