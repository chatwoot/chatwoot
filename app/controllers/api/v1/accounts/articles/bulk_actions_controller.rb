class Api::V1::Accounts::Articles::BulkActionsController < Api::V1::Accounts::BaseController
  before_action :portal
  before_action :check_authorization

  def translate
    head :not_implemented
  end

  private

  def portal
    @portal ||= Current.account.portals.find_by!(slug: params[:portal_id])
  end

  def check_authorization
    authorize(Article, :create?)
  end
end
Api::V1::Accounts::Articles::BulkActionsController.prepend_mod_with('Api::V1::Accounts::Articles::BulkActionsController')
