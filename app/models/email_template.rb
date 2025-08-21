# == Schema Information
#
# Table name: email_templates
#
#  id            :bigint           not null, primary key
#  body          :text             not null
#  locale        :integer          default("en"), not null
#  name          :string           not null
#  slug          :string
#  subject       :string
#  template_type :integer          default("content")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#
# Indexes
#
#  index_email_templates_on_name_and_account_id  (name,account_id) UNIQUE
#
class EmailTemplate < ApplicationRecord
  enum :locale, LANGUAGES_CONFIG.map { |key, val| [val[:iso_639_1_code], key] }.to_h, prefix: true
  enum :template_type, { layout: 0, content: 1 }
  belongs_to :account, optional: true

  before_create :delete_existing_slug_inbox_template

  def self.resolver(options = {})
    ::EmailTemplates::DbResolverService.using self, options
  end

  private

  def delete_existing_slug_inbox_template
    existing = EmailTemplate.find_by(slug: slug, account_id: account_id)
    existing&.destroy
  end
end
