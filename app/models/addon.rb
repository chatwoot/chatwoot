# == Schema Information
#
# Table name: addons
#
#  id                      :bigint           not null, primary key
#  campaign_messages_limit :integer
#  channels_limit          :integer
#  contacts_limit          :integer
#  conversations_limit     :integer
#  description             :text
#  name                    :string           not null
#  status                  :integer          default("active"), not null
#  users_limit             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_addons_on_status  (status)
#
class Addon < ApplicationRecord
  LIMIT_ATTRIBUTES = %i[
    conversations_limit
    contacts_limit
    users_limit
    channels_limit
    campaign_messages_limit
  ].freeze

  enum status: { active: 0, inactive: 1 }

  # An Addon is a catalog entry: an "add-on package" the Super Admin prepares for
  # use. It is not tied to any account or base plan itself; activating an add-on
  # for a specific account (and defining its period) happens through
  # AccountAddon, scoped to the account's assigned package.
  has_many :account_addons, dependent: :destroy_async

  validates :name, presence: true
  # A limit of nil means "no boost". A configured boost is added to the base
  # plan's limit (see Enterprise::Account::PackageLimits#usage_limits).
  validates(*LIMIT_ATTRIBUTES, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true })
end
