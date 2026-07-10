# == Schema Information
#
# Table name: captain_faq_suggestions
#
#  id           :bigint           not null, primary key
#  answer       :text             not null
#  embedding    :vector(1536)
#  question     :string           not null
#  source_count :integer          default(0), not null
#  status       :integer          default("open"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  assistant_id :bigint           not null
#
class Captain::FaqSuggestion < ApplicationRecord
  self.table_name = 'captain_faq_suggestions'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account
  has_many :observations,
           class_name: 'Captain::FaqObservation',
           dependent: :delete_all,
           inverse_of: :faq_suggestion
  has_neighbors :embedding, normalize: true

  enum status: { open: 0, approved: 1, dismissed: 2 }

  validates :question, :answer, presence: true

  before_validation :ensure_account
  after_commit :update_embedding

  scope :ordered, -> { order(source_count: :desc, updated_at: :desc) }

  private

  def ensure_account
    self.account = assistant&.account
  end

  def update_embedding
    return unless open?
    return unless saved_change_to_question? || saved_change_to_answer? || embedding.nil?
    return if previously_new_record? && embedding.present?

    Captain::Llm::UpdateEmbeddingJob.perform_later(self, "#{question}: #{answer}")
  end
end
