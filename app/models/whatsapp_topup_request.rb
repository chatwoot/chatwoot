# == Schema Information
#
# Table name: whatsapp_topup_requests
#
#  id         :bigint           not null, primary key
#  credits    :integer          not null
#  status     :integer          default("pending"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_whatsapp_topup_requests_on_account_id             (account_id)
#  index_whatsapp_topup_requests_on_account_id_and_status  (account_id,status)
#  index_whatsapp_topup_requests_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class WhatsappTopupRequest < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :credits, presence: true, numericality: { greater_than: 0, only_integer: true }

  after_update_commit :credit_account_limit, if: -> { saved_change_to_status? && approved? }

  private

  def credit_account_limit
    current_limits = account.limits || {}
    new_total = current_limits['whatsapp_conversations'].to_i + credits

    account.update!(limits: current_limits.merge('whatsapp_conversations' => new_total))
  end
end
