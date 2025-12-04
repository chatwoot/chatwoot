# == Schema Information
#
# Table name: account_email_templates
#
#  id            :bigint           not null, primary key
#  description   :text
#  friendly_name :string           not null
#  html          :text             not null
#  name          :string           not null
#  template_type :integer          default("content"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  index_account_email_templates_on_account_id           (account_id)
#  index_account_email_templates_on_account_id_and_name  (account_id,name) UNIQUE
#  index_account_email_templates_on_template_type        (template_type)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class AccountEmailTemplate < ApplicationRecord
  belongs_to :account

  enum template_type: { layout: 0, content: 1 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :friendly_name, presence: true
  validates :template_type, presence: true
  validates :html, presence: true
end
