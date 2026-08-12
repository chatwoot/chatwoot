# == Schema Information
#
# Table name: packages
#
#  id                     :bigint           not null, primary key
#  campaign_messages_limit :integer
#  channels_limit         :integer
#  contacts_limit         :integer
#  conversations_limit    :integer
#  description            :text
#  name                   :string           not null
#  status                 :integer          default("active"), not null
#  users_limit            :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_packages_on_status  (status)
#
class Package < ApplicationRecord
  LIMIT_ATTRIBUTES = %i[
    conversations_limit
    contacts_limit
    users_limit
    channels_limit
    campaign_messages_limit
  ].freeze

  enum status: { active: 0, inactive: 1 }

  validates :name, presence: true
  # A limit of nil means "unlimited". A configured limit is a hard cap that the
  # account can never exceed.
  validates(*LIMIT_ATTRIBUTES, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true })

  has_many :account_packages, dependent: :destroy_async
  has_many :accounts, through: :account_packages
end
