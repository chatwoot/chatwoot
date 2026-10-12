# == Schema Information
#
# Table name: whatsapp_interactive_presets
#
#  id               :bigint           not null, primary key
#  archived_at      :datetime
#  definition       :jsonb            not null
#  interactive_type :string           not null
#  name             :string           not null
#  schema_version   :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  created_by_id    :bigint
#
# Indexes
#
#  index_whatsapp_interactive_presets_on_account_id           (account_id)
#  index_whatsapp_interactive_presets_on_account_id_and_name  (account_id,name)
#  index_whatsapp_interactive_presets_on_created_by_id        (created_by_id)
#
class WhatsappInteractivePreset < ApplicationRecord
  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true, inverse_of: :whatsapp_interactive_presets

  validates :name, presence: true, length: { maximum: 255 }
  validates :definition, presence: true
  validate :creator_belongs_to_account, on: :create
  validate :creator_cannot_change, on: :update

  before_validation :normalize_definition

  scope :active, -> { where(archived_at: nil) }
  scope :search_by_name, lambda { |query|
    pattern = "%#{sanitize_sql_like(query.to_s)}%"
    where('name ILIKE ?', pattern)
  }

  def creator_active?
    created_by&.current_account_user.present?
  end

  private

  def normalize_definition
    normalized = Whatsapp::InteractiveMessages::Registry.normalize_preset(definition)
    self.definition = normalized
    self.interactive_type = normalized.fetch('type')
    self.schema_version = normalized.fetch('schema_version')
  rescue Whatsapp::InteractiveMessages::ValidationError => e
    errors.add(:definition, e.message)
  end

  def creator_belongs_to_account
    return if created_by_id.present? && account&.account_users&.exists?(user_id: created_by_id)

    errors.add(:created_by, 'must be an account member')
  end

  def creator_cannot_change
    errors.add(:created_by, 'cannot be changed') if will_save_change_to_created_by_id?
  end
end
