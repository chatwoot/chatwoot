# == Schema Information
#
# Table name: disparos
#
#  id          :integer          not null, primary key
#  companyId   :integer          not null
#  createdAt   :datetime         not null
#  json        :text(4294967295)
#  processedAt :datetime
#
class Trigger < ApplicationRecord
  self.table_name = 'disparos'
  establish_connection :secondary

  belongs_to :account, foreign_key: 'companyId', inverse_of: :triggers

  scope :by_company_ids, ->(company_ids) { where(companyId: company_ids) }
end
