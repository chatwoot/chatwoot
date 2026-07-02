class Autonomia::Prospecting::Lead < ApplicationRecord
  self.table_name = 'autonomia_prospecting_leads'

  belongs_to :account
  belongs_to :search, class_name: 'Autonomia::Prospecting::Search', foreign_key: :prospect_search_id, optional: true, inverse_of: :leads
  belongs_to :contact, optional: true
  belongs_to :crm_card, class_name: 'Crm::Card', optional: true

  has_many :list_leads, class_name: 'Autonomia::Prospecting::ListLead', foreign_key: :prospect_lead_id, dependent: :destroy,
                        inverse_of: :lead
  has_many :lists, through: :list_leads, source: :list

  enum status: { new_lead: 0, qualified: 1, discarded: 2, no_consent: 3, ready_for_campaign: 4 }

  before_validation :ensure_dedupe_key

  validates :name, presence: true
  validates :provider, presence: true
  validates :dedupe_key, presence: true, uniqueness: { scope: :account_id }
  validate :linked_records_must_belong_to_account

  private

  def ensure_dedupe_key
    self.dedupe_key ||= [provider, provider_place_id.presence || name.to_s.downcase.strip].join(':')
  end

  def linked_records_must_belong_to_account
    validate_same_account(:search)
    validate_same_account(:contact)
    validate_same_account(:crm_card)
  end

  def validate_same_account(association_name)
    record = public_send(association_name)
    return if record.blank? || account_id.blank?
    return if record.account_id == account_id

    errors.add(association_name, 'must belong to the same account')
  end
end
