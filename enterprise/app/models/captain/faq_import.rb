class Captain::FaqImport < ApplicationRecord
  self.table_name = 'captain_faq_imports'

  STALLED_AFTER = 15.minutes
  ROW_STATES = {
    valid: 'valid',
    invalid: 'invalid',
    duplicate: 'duplicate',
    existing: 'existing'
  }.freeze
  IMPORTABLE_ROW_STATES = ROW_STATES.values_at(:valid, :existing).freeze
  RESOLUTIONS = { skip: 'skip', overwrite: 'overwrite' }.freeze
  EMBEDDING_STATES = { pending: 'pending', ready: 'ready', failed: 'failed' }.freeze
  TERMINAL_EMBEDDING_STATES = EMBEDDING_STATES.values_at(:ready, :failed).freeze

  class InvalidStateError < StandardError; end
  class ActiveImportError < StandardError; end

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :user, optional: true

  enum :status, {
    preview: 0,
    preparing: 1,
    completed: 2,
    completed_with_errors: 3,
    failed: 4
  }

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :latest_first, -> { order(created_at: :desc) }

  validates :original_filename, presence: true
  validates :user, presence: true, on: :create
  validate :assistant_belongs_to_account

  def confirm!(overwrite_row_numbers)
    selected_rows = Array(overwrite_row_numbers).to_set(&:to_i)

    with_lock do
      raise InvalidStateError unless preview?

      updated_rows = rows.map do |row|
        next row unless row['state'] == ROW_STATES[:existing]

        resolution = selected_rows.include?(row['row_number'].to_i) ? RESOLUTIONS[:overwrite] : RESOLUTIONS[:skip]
        row.merge('resolution' => resolution)
      end

      update!(rows: updated_rows, status: :preparing, confirmed_at: Time.current)
    end
  end

  def mark_embedding!(response_id, success:)
    with_lock do
      return unless preparing?

      updated_rows = rows.deep_dup
      row = updated_rows.find { |item| item['response_id'].to_i == response_id.to_i }
      return if row.blank? || TERMINAL_EMBEDDING_STATES.include?(row['embedding_state'])

      row['embedding_state'] = success ? EMBEDDING_STATES[:ready] : EMBEDDING_STATES[:failed]
      self.rows = updated_rows
      success ? self.embedding_ready_count += 1 : self.embedding_failed_count += 1
      finish_if_embeddings_complete
      save!
    end
  end

  def complete_if_ready!
    with_lock do
      return unless preparing?
      return unless rows_processed?
      return unless embeddings_processed?

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

  def invalid_rows
    rows.select { |row| row['state'] == ROW_STATES[:invalid] }
  end

  def stalled?
    preparing? && updated_at <= STALLED_AFTER.ago
  end

  def claim_stalled_recovery!
    with_lock do
      return unless stalled?

      update!(updated_at: Time.current)
      updated_at
    end
  end

  def recovery_claim_current?(claimed_at)
    preparing? && updated_at == claimed_at
  end

  private

  def finish_if_embeddings_complete
    return unless embeddings_processed?

    finish!
  end

  def embeddings_processed?
    embedding_ready_count + embedding_failed_count >= created_count + overwritten_count
  end

  def finish!
    has_errors = import_has_errors?

    self.status = has_errors ? :completed_with_errors : :completed
    self.completed_at = Time.current
    self.rows = []
  end

  def import_has_errors?
    embedding_failed_count.positive? || invalid_rows.any?
  end

  def assistant_belongs_to_account
    return if assistant.blank? || assistant.account_id == account_id

    errors.add(:assistant, :invalid)
  end
end
