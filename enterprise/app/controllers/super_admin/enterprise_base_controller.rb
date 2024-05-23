class SuperAdmin::EnterpriseBaseController < SuperAdmin::ApplicationController
  before_action :prepend_view_paths

  # Prepend the view path to the enterprise/app/views won't be available by default
  def prepend_view_paths
    prepend_view_path 'enterprise/app/views/'
  end
end
