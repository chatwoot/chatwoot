class Api::V1::Accounts::Captain::ToolCatalogSetupOperationsController < Api::V1::Accounts::Captain::ToolCatalogBaseController
  def create
    result = Captain::ToolCatalog::SetupOperationExecutor.new(account: Current.account).perform(
      provider_key: params[:provider_key],
      operation_key: params[:operation_key],
      arguments: setup_params[:arguments].to_h
    )
    render json: { payload: result }
  end

  private

  def setup_params
    return {} if params[:setup].blank?

    params.require(:setup).permit(arguments: {})
  end
end
