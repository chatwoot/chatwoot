class Onehash::Cal::ActionController < Onehash::IntegrationController
  def destroy
    account_user_id = params[:id]

    return render json: { error: 'Account User Id is required' }, status: :bad_request unless account_user_id

    account_user = AccountUser.find_by(id: account_user_id)
    return render json: { error: 'Account User not found' }, status: :not_found unless account_user

    Rails.logger.info "Deleting Account User ID: #{account_user_id}"

    Integrations::Hook.where(account_user_id: account_user.id, app_id: 'onehash_cal').destroy_all

    render json: { message: 'Account User hooks deleted successfully' }, status: :ok
  end
end
