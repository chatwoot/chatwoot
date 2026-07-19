# == Schema Information
#
# Table name: custom_attribute_definitions
#
#  id                     :bigint           not null, primary key
#  attribute_description  :text
#  attribute_display_name :string
#  attribute_display_type :integer          default("text")
#  attribute_key          :string
#  attribute_model        :integer          default("conversation_attribute")
#  attribute_values       :jsonb
#  default_value          :integer
#  featured               :boolean          default(FALSE), not null
#  formula                :jsonb
#  regex_cue              :string
#  regex_pattern          :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  attribute_key_model_index                         (attribute_key,attribute_model,account_id) UNIQUE
#  index_custom_attribute_definitions_on_account_id  (account_id)
#
class CustomAttributeDefinition < ApplicationRecord
  STANDARD_ATTRIBUTES = {
    :conversation => %w[status priority assignee_id inbox_id team_id display_id campaign_id labels browser_language country_code referer created_at
                        last_activity_at],
    :contact => %w[name email phone_number identifier country_code city company_name created_at last_activity_at referer blocked],
    :company => %w[name domain description contacts_count created_at updated_at last_activity_at]
  }.freeze

  FORMULA_OPS = %w[sum avg count].freeze
  MAX_FEATURED_PER_MODEL = 2

  scope :with_attribute_model, ->(attribute_model) { attribute_model.presence && where(attribute_model: attribute_model) }
  validates :attribute_display_name, presence: true
  before_validation :normalize_attribute_fields
  before_validation :normalize_formula

  validates :attribute_key,
            presence: true,
            uniqueness: { scope: [:account_id, :attribute_model] },
            format: { with: /\A[\p{L}\p{N}_.\-]+\z/, message: I18n.t('errors.custom_attribute_definition.attribute_key_format') }

  validates :attribute_display_type, presence: true
  validates :attribute_model, presence: true
  validate :attribute_must_not_conflict, on: :create
  validate :validate_featured_limit
  validate :validate_formula

  enum attribute_model: { conversation_attribute: 0, contact_attribute: 1, company_attribute: 2 }
  enum attribute_display_type: { text: 0, number: 1, currency: 2, percent: 3, link: 4, date: 5, list: 6, checkbox: 7 }

  belongs_to :account
  after_update :update_widget_pre_chat_custom_fields, unless: :company_attribute?
  after_destroy :sync_widget_pre_chat_custom_fields, unless: :company_attribute?
  after_commit :enqueue_contact_formula_recompute, on: [:create, :update]

  def formula?
    formula.present?
  end

  private

  def enqueue_contact_formula_recompute
    return unless contact_attribute?
    return unless formula?

    CustomAttributes::RecomputeAccountContactFormulasJob.perform_later(account_id)
  end

  def normalize_attribute_fields
    self.attribute_key = attribute_key.strip if attribute_key.present?
    self.attribute_display_name = attribute_display_name.strip if attribute_display_name.present?
    self.featured = false if featured.nil?
  end

  def normalize_formula
    return if formula.blank?

    self.formula = nil if formula.is_a?(Hash) && formula.values.all?(&:blank?)
  end

  def sync_widget_pre_chat_custom_fields
    ::Inboxes::SyncWidgetPreChatCustomFieldsJob.perform_later(account, attribute_key)
  end

  def update_widget_pre_chat_custom_fields
    ::Inboxes::UpdateWidgetPreChatCustomFieldsJob.perform_later(account, self)
  end

  def attribute_must_not_conflict
    model_keys = attribute_model.to_s.delete_suffix('_attribute').to_sym
    standard_attributes = STANDARD_ATTRIBUTES[model_keys]
    return if standard_attributes.blank?
    return unless attribute_key.in?(standard_attributes)

    errors.add(:attribute_key, I18n.t('errors.custom_attribute_definition.key_conflict'))
  end

  def validate_featured_limit
    return unless featured?
    return if account.blank?

    scope = account.custom_attribute_definitions.where(attribute_model: attribute_model, featured: true)
    scope = scope.where.not(id: id) if persisted?
    return if scope.count < MAX_FEATURED_PER_MODEL

    errors.add(:featured, 'maximum featured attributes reached for this model')
  end

  def validate_formula
    return if formula.blank?

    unless contact_attribute?
      errors.add(:formula, 'only allowed on contact attributes')
      return
    end

    op = formula['op'].to_s
    source_key = formula['source_attribute_key'].to_s
    source_model = formula['source_model'].to_s.presence || 'conversation'

    errors.add(:formula, 'invalid operation') unless FORMULA_OPS.include?(op)
    errors.add(:formula, 'source_attribute_key required') if source_key.blank?
    errors.add(:formula, 'source_model must be conversation') unless source_model == 'conversation'
  end
end

CustomAttributeDefinition.include_mod_with('Concerns::CustomAttributeDefinition')
