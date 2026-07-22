# == Schema Information
#
# Table name: captain_faq_observations
#
#  id                 :bigint           not null, primary key
#  generated_answer   :text             not null
#  generated_question :string           not null
#  language           :string           default("en"), not null
#  status             :integer          default("attached"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  conversation_id    :bigint           not null
#  faq_suggestion_id  :bigint
#
class Captain::FaqObservation < ApplicationRecord
  self.table_name = 'captain_faq_observations'

  belongs_to :account
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :faq_suggestion, class_name: 'Captain::FaqSuggestion', optional: true, inverse_of: :observations

  enum status: { attached: 0, discarded: 1 }

  validates :generated_question, :generated_answer, :language, presence: true
  validates :faq_suggestion, presence: true, if: :attached?
  validate :faq_suggestion_belongs_to_account

  before_validation :ensure_account

  private

  def ensure_account
    self.account = conversation&.account
  end

  def faq_suggestion_belongs_to_account
    return if faq_suggestion.blank? || faq_suggestion.account_id == account_id

    errors.add(:faq_suggestion, :invalid)
  end
end
