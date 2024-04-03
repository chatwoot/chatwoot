module Enterprise::Concerns::ApplicationControllerConcern
  extend ActiveSupport::Concern

  included do
    before_action :prepend_view_paths
  end

  # Prepend the view path to the enterprise/app/views won't be available by default
  def prepend_view_paths
    prepend_view_path 'enterprise/app/views/'
  end
end
