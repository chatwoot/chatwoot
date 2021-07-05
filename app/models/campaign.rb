# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  description   :text
#  enabled       :boolean          default(TRUE)
#  message       :text             not null
#  title         :string           not null
#  trigger_rules :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  display_id    :integer          not null
#  inbox_id      :bigint           not null
#  sender_id     :integer
#
# Indexes
#
#  index_campaigns_on_account_id  (account_id)
#  index_campaigns_on_inbox_id    (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class Campaign < ApplicationRecord
  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :title, presence: true
  validates :message, presence: true
  belongs_to :account
  belongs_to :inbox
  belongs_to :sender, class_name: 'User', optional: true

  has_many :conversations, dependent: :nullify, autosave: true

  after_commit :set_display_id, unless: :display_id?

  private

  def set_display_id
    reload
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end
end
