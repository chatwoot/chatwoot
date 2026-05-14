# == Schema Information
#
# Table name: help_center_generations
#
#  id                :bigint           not null, primary key
#  articles_finished :integer          default(0), not null
#  finished_at       :datetime
#  plan              :jsonb
#  skip_reason       :text
#  started_at        :datetime
#  status            :integer          default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  portal_id         :bigint           not null
#
# Indexes
#
#  index_help_center_generations_on_account_id  (account_id)
#  index_help_center_generations_on_portal_id   (portal_id)
#
class HelpCenterGeneration < ApplicationRecord
  belongs_to :account
  belongs_to :portal

  enum :status, { pending: 0, curating: 1, generating: 2, completed: 3, skipped: 4 }

  after_create_commit :enqueue_generation_job

  def terminal?
    completed? || skipped?
  end

  def planned_total
    plan&.dig('articles')&.size.to_i
  end

  def all_finished?
    articles_finished >= planned_total
  end

  def start_curating!
    return unless pending?

    update!(status: :curating, started_at: Time.current)
  end

  def start_generating!(plan:)
    update!(plan: plan, status: :generating)
  end

  def mark_skipped!(reason:)
    update!(status: :skipped, skip_reason: reason, finished_at: Time.current)
  end

  def record_article_finished!
    self.class.update_counters(id, articles_finished: 1) # rubocop:disable Rails/SkipsModelValidations
    reload
  end

  def complete_if_finished!
    updated = self.class
                  .where(id: id, status: self.class.statuses[:generating])
                  .where('articles_finished >= ?', planned_total)
                  .update_all(status: self.class.statuses[:completed], finished_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    return false unless updated == 1

    reload
    true
  end

  private

  def enqueue_generation_job
    Onboarding::HelpCenterArticleGenerationJob.perform_later(self)
  end
end
