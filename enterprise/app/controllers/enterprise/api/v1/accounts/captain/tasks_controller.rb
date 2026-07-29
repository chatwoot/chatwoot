module Enterprise::Api::V1::Accounts::Captain::TasksController
  extend ActiveSupport::Concern

  prepended do
    include Enterprise::Concerns::CaptainFeatureGuard

    before_action :ensure_captain_enabled
  end
end
