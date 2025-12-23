module ScoutApm
  module Rack
    def self.install!
      ScoutApm::Agent.instance.start(:skip_app_server_check => true)
      ScoutApm::Agent.instance.start_background_worker
    end

    def self.transaction(endpoint_name, env)
      req = ScoutApm::RequestManager.lookup
      req.annotate_request(:uri => env["REQUEST_PATH"]) rescue nil
      req.context.add_user(:ip => env["REMOTE_ADDR"]) rescue nil

      layer = ScoutApm::Layer.new('Controller', endpoint_name)
      req.start_layer(layer)

      begin
        yield
      rescue
        req.error!
        raise
      ensure
        req.stop_layer
      end
    end
  end
end
