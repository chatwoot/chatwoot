module ScoutApm
  module ErrorService
    class Railtie < Rails::Railtie
      initializer "scoutapm_error_service.middleware" do |app|
        next if ScoutApm::Agent.instance.config.value("error_service")

        app.config.middleware.insert_after ActionDispatch::DebugExceptions, ScoutApm::ErrorService::Rack
      end
    end
  end
end
