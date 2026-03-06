class WhatsappCall < ApplicationRecord
  STATUSES = %w[ringing accepted rejected missed ended failed].freeze
  DIRECTIONS = %w[inbound outbound].freeze

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :accepted_by_agent, class_name: 'User', optional: true

  validates :call_id, presence: true, uniqueness: true
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: %w[ringing accepted]) }
  scope :ringing, -> { where(status: 'ringing') }

  def accepted?
    status == 'accepted'
  end

  def ringing?
    status == 'ringing'
  end

  def terminal?
    %w[rejected missed ended failed].include?(status)
  end

  def sdp_offer
    meta['sdp_offer']
  end

  def ice_servers
    meta['ice_servers'] || []
  end
end
