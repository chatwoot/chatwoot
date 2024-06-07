class Trigger < ApplicationRecord
  self.table_name = 'disparos'
  establish_connection :secondary

  scope :by_company_ids, ->(company_ids) { where(companyId: company_ids) }
end
