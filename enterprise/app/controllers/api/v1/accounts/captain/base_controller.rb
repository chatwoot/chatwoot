class Api::V1::Accounts::Captain::BaseController < Api::V1::Accounts::BaseController
  include Enterprise::Concerns::CaptainFeatureGuard

  before_action :ensure_captain_enabled
end
