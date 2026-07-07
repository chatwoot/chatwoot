# == Schema Information
#
# Table name: autonomia_prospecting_leads
#
#  id                 :bigint           not null, primary key
#  address            :string
#  category           :string
#  city               :string
#  country            :string
#  dedupe_key         :string           not null
#  discard_reason     :string
#  latitude           :decimal(10, 6)
#  longitude          :decimal(10, 6)
#  metadata           :jsonb            not null
#  name               :string           not null
#  phone              :string
#  provider           :string           default("mock"), not null
#  rating             :decimal(3, 2)
#  raw_payload        :jsonb            not null
#  reviews_count      :integer
#  state              :string
#  status             :integer          default("new_lead"), not null
#  website            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  contact_id         :bigint
#  crm_card_id        :bigint
#  prospect_search_id :bigint
#  provider_place_id  :string
#
# Indexes
#
#  idx_autonomia_prospecting_leads_provider_place                  (account_id,provider,provider_place_id) UNIQUE WHERE (provider_place_id IS NOT NULL)
#  index_autonomia_prospecting_leads_on_account_id                 (account_id)
#  index_autonomia_prospecting_leads_on_account_id_and_dedupe_key  (account_id,dedupe_key) UNIQUE
#  index_autonomia_prospecting_leads_on_account_id_and_status      (account_id,status)
#  index_autonomia_prospecting_leads_on_contact_id                 (contact_id)
#  index_autonomia_prospecting_leads_on_crm_card_id                (crm_card_id)
#  index_autonomia_prospecting_leads_on_search_id                  (prospect_search_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => nullify
#  fk_rails_...  (crm_card_id => crm_cards.id) ON DELETE => nullify
#  fk_rails_...  (prospect_search_id => autonomia_prospecting_searches.id) ON DELETE => nullify
#
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
  validates :discard_reason, presence: true, if: :discarded?
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
