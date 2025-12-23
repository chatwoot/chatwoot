
module ScoutApm
  def self.AutoInstrument(name, backtrace)
    request = ScoutApm::RequestManager.lookup

    file_name, _ = backtrace.first.split(":", 2)

    begin
      layer = ScoutApm::Layer.new('AutoInstrument', name)
      layer.backtrace = backtrace
      layer.file_name = file_name

      request.start_layer(layer)
      started_layer = true

      result = yield
    ensure
      request.stop_layer if started_layer
    end

    return result
  end
end
