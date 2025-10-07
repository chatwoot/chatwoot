# == Schema Information
#
# Table name: surveys
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_surveys_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class Survey < ApplicationRecord
  belongs_to :account
  has_many :survey_questions, dependent: :destroy
  has_many :survey_question_options, through: :survey_questions
  has_many :inboxes, dependent: :nullify
  has_many :contact_survey_completions, dependent: :destroy

  accepts_nested_attributes_for :survey_questions, allow_destroy: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def questions_count
    survey_questions.count
  end
end
