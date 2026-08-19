class Captain::FaqImport < ApplicationRecord
  self.table_name = 'captain_faq_imports'

  STALLED_AFTER = 15.minutes

  class InvalidStateError < StandardError; end

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :user

  has_one_attached :source_file

  enum :status, {
    preview: 0,
    preparing: 1,
    completed: 2,
    completed_with_errors: 3,
    failed: 4
  }

  scope :active, -> { where(status: [:preview, :preparing]) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :latest_first, -> { order(created_at: :desc) }

  validates :original_filename, :checksum, presence: true
  validate :assistant_belongs_to_account

  def confirm!(overwrite_row_numbers)
    selected_rows = Array(overwrite_row_numbers).to_set(&:to_i)

    with_lock do
      raise InvalidStateError unless preview?

      updated_rows = rows.map do |row|
        next row unless row['state'] == 'existing'

        row.merge('resolution' => selected_rows.include?(row['row_number'].to_i) ? 'overwrite' : 'skip')
      end

      update!(rows: updated_rows, status: :preparing, confirmed_at: Time.current)
    end
  end

  def mark_embedding!(response_id, success:)
    with_lock do
      return unless preparing?

      updated_rows = rows.deep_dup
      row = updated_rows.find { |item| item['response_id'].to_i == response_id.to_i }
      return if row.blank? || %w[ready failed].include?(row['embedding_state'])

      row['embedding_state'] = success ? 'ready' : 'failed'
      self.rows = updated_rows
      success ? self.embedding_ready_count += 1 : self.embedding_failed_count += 1
      finish_if_embeddings_complete
      save!
    end
  end

  def finish_if_no_embeddings!
    with_lock do
      return unless preparing?
      return unless (created_count + overwritten_count).zero?

      finish!
      save!
    end
  end

  def fail!(message)
    with_lock do
      update!(status: :failed, error_message: message.to_s.truncate(1000), completed_at: Time.current) if preparing?
    end
  end

  def rows_processed?
    created_count + overwritten_count + skipped_count == row_count
  end

  def stalled?
    preparing? && updated_at <= STALLED_AFTER.ago
  end

  private

  def finish_if_embeddings_complete
    return unless embedding_ready_count + embedding_failed_count >= created_count + overwritten_count

    finish!
  end

  def finish!
    self.status = import_has_errors? ? :completed_with_errors : :completed
    self.completed_at = Time.current
  end

  def import_has_errors?
    embedding_failed_count.positive? || rows.any? { |row| row['state'] == 'invalid' }
  end

  def assistant_belongs_to_account
    return if assistant.blank? || assistant.account_id == account_id

    errors.add(:assistant, :invalid)
  end
end
