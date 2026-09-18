class DataImports::RunState
  def initialize(data_import, run_id)
    @data_import = data_import
    @run_id = run_id
  end

  def active?
    (@data_import.pending? || @data_import.processing?) &&
      (@run_id.blank? || @data_import.active_import_run_id == @run_id)
  end

  def with_lock
    @data_import.with_lock do
      next unless active?

      yield
    end
  end

  def start!
    with_lock { @data_import.update!(status: :processing, started_at: @data_import.started_at || Time.current) }
  end

  def heartbeat!
    with_lock { @data_import.update!(updated_at: Time.current) }
  end
end
