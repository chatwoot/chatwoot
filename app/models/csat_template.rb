# == Schema Information
#
# Table name: csat_templates
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_csat_templates_on_account_id  (account_id)
#
class CsatTemplate < ApplicationRecord
  belongs_to :account
  has_many :csat_template_questions, dependent: :nullify
  has_many :inboxes, dependent: :destroy

  accepts_nested_attributes_for :csat_template_questions, allow_destroy: true

  def questions_count
    csat_template_questions.count
  end
end
