class WhatsappInteractiveTemplate < ApplicationRecord
  HEADER_TYPES = %w[none text image].freeze
  TEMPLATE_TYPES = %w[cta_url].freeze

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }
  validates :header_type, presence: true, inclusion: { in: HEADER_TYPES }
  validates :body_text, presence: true
  validates :button_text, presence: true
  validates :payload, presence: true

  scope :cta_url, -> { where(template_type: 'cta_url') }

  def cta_url?
    template_type == 'cta_url'
  end
end
