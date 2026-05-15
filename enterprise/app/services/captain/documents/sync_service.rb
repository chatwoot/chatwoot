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
    @document.update!(sync_step: 'fetching')
    result = Captain::Documents::SinglePageFetcher.new(@document.external_link).fetch

    handle_fetch_error(result.error_code) unless result.success

    @document.update!(sync_step: 'comparing')
    new_fingerprint = compute_fingerprint(result.content)
    previous_fingerprint = @document.content_fingerprint

    if new_fingerprint == previous_fingerprint
      mark_synced
      return :unchanged
    end

    @document.update!(sync_step: 'updating')
    update_content(result, new_fingerprint)

    # Without a prior fingerprint we cannot tell a first-ever sync apart from a real
    # change, so treat it as unchanged to keep downstream signals quiet on baseline.
    previous_fingerprint.present? ? :updated : :unchanged
  end

  private

  def compute_fingerprint(content)
    Digest::SHA256.hexdigest(content.gsub(/\s+/, ' ').strip)
  end

  def mark_failed(error_code)
    @document.update!(
      sync_status: :failed,
      sync_step: nil,
      last_sync_error_code: error_code,
      last_sync_attempted_at: Time.current
    )
  end

  def mark_synced
    @document.update!(
      sync_status: :synced,
      sync_step: nil,
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
      sync_step: nil,
      last_synced_at: Time.current,
      last_sync_attempted_at: Time.current,
      last_sync_error_code: nil
    )
  end

  def handle_fetch_error(error_code)
    if PERMANENT_ERROR_CODES.include?(error_code)
      mark_failed(error_code)
      raise PermanentSyncError, error_code
    end

    raise TransientSyncError, error_code
  end
end
