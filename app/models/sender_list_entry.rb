# == Schema Information
#
# Table name: sender_list_entries
#
#  id         :bigint           not null, primary key
#  list_type  :integer          not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_sender_list_entries_on_account_id            (account_id)
#  index_sender_list_entries_on_account_id_and_value  (account_id,value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class SenderListEntry < ApplicationRecord
  DOMAIN_REGEX = /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+\z/

  belongs_to :account

  enum list_type: { vip: 0, blocked: 1, allowed: 2 }

  before_validation :normalize_value

  validates :value, presence: true, uniqueness: { scope: :account_id }
  validate :validate_value_format

  def self.normalize(value)
    value.to_s.strip.downcase
  end

  # Returns 'vip', 'blocked', 'allowed' or nil for the given sender address.
  # An exact email entry always wins over an entry for the sender domain.
  def self.list_type_for(account:, email:)
    address = normalize(email)
    domain = address.split('@').last
    return if domain.blank?

    entries = where(account: account, value: [address, domain]).index_by(&:value)
    (entries[address] || entries[domain])&.list_type
  end

  private

  def normalize_value
    self.value = self.class.normalize(value)
  end

  def validate_value_format
    return if value.blank?
    return if value.include?('@') ? value.match?(URI::MailTo::EMAIL_REGEXP) : value.match?(DOMAIN_REGEX)

    errors.add(:value, 'must be a valid email address or domain')
  end
end
