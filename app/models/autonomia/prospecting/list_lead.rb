class Autonomia::Prospecting::ListLead < ApplicationRecord
  self.table_name = 'autonomia_prospecting_list_leads'

  belongs_to :account
  belongs_to :list, class_name: 'Autonomia::Prospecting::List', foreign_key: :prospect_list_id, inverse_of: :list_leads
  belongs_to :lead, class_name: 'Autonomia::Prospecting::Lead', foreign_key: :prospect_lead_id, inverse_of: :list_leads

  validates :prospect_lead_id, uniqueness: { scope: :prospect_list_id }
  validate :records_must_belong_to_account

  private

  def records_must_belong_to_account
    validate_same_account(:list)
    validate_same_account(:lead)
  end

  def validate_same_account(association_name)
    record = public_send(association_name)
    return if record.blank? || account_id.blank?
    return if record.account_id == account_id

    errors.add(association_name, 'must belong to the same account')
  end
end
