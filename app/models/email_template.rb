# == Schema Information
#
# Table name: email_templates
#
#  id            :bigint           not null, primary key
#  body          :text             not null
#  locale        :integer          default("en"), not null
#  name          :string           not null
#  template_type :integer          default("content")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#  inbox_id      :integer
#
# Indexes
#
#  index_email_templates_on_account_scope       (account_id,name,template_type,locale) UNIQUE WHERE ((account_id IS NOT NULL) AND (inbox_id IS NULL))
#  index_email_templates_on_inbox_id            (inbox_id)
#  index_email_templates_on_inbox_scope         (inbox_id,name,template_type,locale) UNIQUE WHERE (inbox_id IS NOT NULL)
#  index_email_templates_on_installation_scope  (name,template_type,locale) UNIQUE WHERE ((account_id IS NULL) AND (inbox_id IS NULL))
#
class EmailTemplate < ApplicationRecord
  BRANDED_LAYOUT_NAME = 'base'.freeze
  DEFAULT_LOCALE = 'en'.freeze
  CONTENT_FOR_LAYOUT_PATTERN = /\{\{\s*content_for_layout\s*\}\}/

  enum :locale, LANGUAGES_CONFIG.map { |key, val| [val[:iso_639_1_code], key] }.to_h, prefix: true
  enum :template_type, { layout: 0, content: 1 }
  belongs_to :account, optional: true
  belongs_to :inbox, optional: true

  validates :name,
            uniqueness: { scope: %i[template_type locale], conditions: -> { where(account_id: nil, inbox_id: nil) } },
            if: :installation_scoped?
  validates :name, uniqueness: { scope: %i[account_id template_type locale], conditions: -> { where(inbox_id: nil) } }, if: :account_scoped?
  validates :name, uniqueness: { scope: %i[inbox_id template_type locale] }, if: :inbox_scoped?
  validate :validate_inbox_account
  validate :validate_liquid_body
  validate :validate_layout_slot, if: :layout?

  def self.resolver(options = {})
    ::EmailTemplates::DbResolverService.using self, options
  end

  def self.branded_layout_for(inbox:, account:, locale: I18n.locale)
    layout_template_for_scope(inbox: inbox, account: account, locale: locale)
  end

  def self.account_branded_layout_template_for(account)
    find_by(account: account, inbox: nil, name: BRANDED_LAYOUT_NAME, template_type: :layout, locale: DEFAULT_LOCALE)
  end

  def self.update_account_branded_layout!(account:, body:)
    if body.blank?
      account_branded_layout_template_for(account)&.destroy!
      return
    end

    template = account_branded_layout_template_for(account) || new(
      account: account,
      name: BRANDED_LAYOUT_NAME,
      template_type: :layout,
      locale: DEFAULT_LOCALE
    )
    template.update!(body: body)
  end

  def self.locale_candidates(locale)
    candidate = locale.to_s
    ([candidate] + [DEFAULT_LOCALE]).select { |locale_key| locales.key?(locale_key) }.uniq
  end

  def self.layout_template_for_scope(inbox:, account:, locale:)
    scoped_relations = []
    scoped_relations << where(inbox: inbox) if inbox.present?
    scoped_relations << where(account: account, inbox: nil) if account.present?
    scoped_relations << where(account: nil, inbox: nil)

    scoped_relations.each do |relation|
      locale_candidates(locale).each do |locale_key|
        template = relation.find_by(name: BRANDED_LAYOUT_NAME, template_type: :layout, locale: locale_key)
        return template if template.present?
      end
    end
    nil
  end

  private

  def installation_scoped?
    account_id.nil? && inbox_id.nil?
  end

  def account_scoped?
    account_id.present? && inbox_id.nil?
  end

  def inbox_scoped?
    inbox_id.present?
  end

  def validate_inbox_account
    return if inbox.blank? || account.blank?
    return if inbox.account_id == account_id

    errors.add(:account, 'must match inbox account')
  end

  def validate_liquid_body
    Liquid::Template.parse(body.to_s)
  rescue Liquid::Error => e
    errors.add(:body, "has invalid Liquid syntax: #{e.message}")
  end

  def validate_layout_slot
    return if body.to_s.match?(CONTENT_FOR_LAYOUT_PATTERN)

    errors.add(:body, 'must include {{ content_for_layout }}')
  end
end
