class Captain::Documents::SyncService
  class PermanentSyncError < StandardError
  end

  class TransientSyncError < StandardError
  end

  PERMANENT_ERROR_CODES = %w[not_found access_denied content_empty].freeze

  def initialize(document)
    @document = document
  end

  def perform
    @document.store_sync_step('fetching')
    result = Captain::Documents::SinglePageFetcher.new(@document.external_link).fetch

    unless result.success
      mark_failed(result.error_code)
      raise_for_error_code(result.error_code)
    end

    @document.store_sync_step('comparing')
    fingerprint = compute_fingerprint(result.content)

    if fingerprint == @document.content_fingerprint
      mark_synced
      return :unchanged
    end

    @document.store_sync_step('updating')
    update_content(result, fingerprint)
    :updated
  end

  private

  def compute_fingerprint(content)
    Digest::SHA256.hexdigest(content.gsub(/\s+/, ' ').strip)
  end

  def mark_failed(error_code)
    @document.update!(
      sync_status: :failed,
      last_sync_error_code: error_code,
      last_sync_attempted_at: Time.current
    )
  end

  def mark_synced
    @document.update!(
      sync_status: :synced,
      last_synced_at: Time.current,
      last_sync_attempted_at: Time.current,
      last_sync_error_code: nil
    )
  end

  def update_content(result, fingerprint)
    @document.update!(
      content: result.content,
      name: result.title.presence || @document.name,
      content_fingerprint: fingerprint,
      sync_status: :synced,
      last_synced_at: Time.current,
      last_sync_attempted_at: Time.current,
      last_sync_error_code: nil
    )
  end

  def raise_for_error_code(error_code)
    raise PermanentSyncError, error_code if PERMANENT_ERROR_CODES.include?(error_code)

    raise TransientSyncError, error_code
  end
end
