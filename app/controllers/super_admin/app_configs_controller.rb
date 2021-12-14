class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
    def show
        @config = InstallationConfig.first
    end
end
