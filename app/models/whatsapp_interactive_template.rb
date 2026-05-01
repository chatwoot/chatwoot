class WhatsappInteractiveTemplate < ApplicationRecord
  HEADER_TYPES = %w[none text image].freeze
  TEMPLATE_TYPES = %w[cta_url rich_text quick_replies].freeze

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }
  validates :header_type, presence: true, inclusion: { in: HEADER_TYPES }
  validates :body_text, presence: true
  validates :button_text, presence: true, if: :cta_url?
  validates :payload, presence: true

  scope :cta_url, -> { where(template_type: 'cta_url') }
  scope :rich_text, -> { where(template_type: 'rich_text') }
  scope :quick_replies, -> { where(template_type: 'quick_replies') }

  def cta_url?
    template_type == 'cta_url'
  end

  def rich_text?
    template_type == 'rich_text'
  end

  def quick_replies?
    template_type == 'quick_replies'
  end
end
