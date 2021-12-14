class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
    def show
        @fb_config = InstallationConfig.where('name LIKE ?', "FB_" + '%')
    end
end
