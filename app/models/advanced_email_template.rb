# == Schema Information
#
# Table name: advanced_email_templates
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
#  index_advanced_email_templates_on_account_id           (account_id)
#  index_advanced_email_templates_on_account_id_and_name  (account_id,name)
#  index_advanced_email_templates_on_template_type        (template_type)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class AdvancedEmailTemplate < ApplicationRecord
  belongs_to :account

  has_many :user_assignments, dependent: :destroy
  has_many :users, through: :user_assignments

  # NEW: Use Enum to map integers to words
  enum template_type: { layout: 0, content: 1 }

  validates :name, presence: true
  validates :friendly_name, presence: true
  validates :template_type, presence: true
  validates :html, presence: true
end
